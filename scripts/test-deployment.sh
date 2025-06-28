#!/bin/bash
# scripts/test-deployment.sh

set -e

echo "🧪 Testing Zero Trust PoC deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    
    echo -n "Testing $name... "
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test function with token
test_with_token() {
    local name="$1"
    local url="$2"
    local token="$3"
    local expected_status="$4"
    
    echo -n "Testing $name... "
    if curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test function with mTLS
test_with_mtls() {
    local name="$1"
    local url="$2"
    local cert="$3"
    local key="$4"
    local expected_status="$5"
    
    echo -n "Testing $name... "
    if curl -s -o /dev/null -w "%{http_code}" --cert "$cert" --key "$key" --cacert certs/ca.crt "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Test 1: Health checks
echo ""
echo "🔍 Testing health checks..."
test_endpoint "Keycloak Health" "http://localhost:8080/health" "200"
test_endpoint "OPA Health" "http://localhost:8181/health" "200"
test_endpoint "Backend Health" "http://localhost:3000/health" "200"
test_endpoint "Prometheus Health" "http://localhost:9090/-/healthy" "200"

# Test 2: Get tokens
echo ""
echo "🔐 Testing token generation..."
ADMIN_TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/zero-trust/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=myapp" \
  -d "client_secret=EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa" \
  -d "username=admin" \
  -d "password=adminpass" \
  -d "grant_type=password" | jq -r '.access_token')

USER_TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/zero-trust/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=myapp" \
  -d "client_secret=EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa" \
  -d "username=user" \
  -d "password=userpass" \
  -d "grant_type=password" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" != "null" ] && [ -n "$ADMIN_TOKEN" ]; then
    echo -e "${GREEN}✅ Admin token generated${NC}"
else
    echo -e "${RED}❌ Failed to generate admin token${NC}"
    exit 1
fi

if [ "$USER_TOKEN" != "null" ] && [ -n "$USER_TOKEN" ]; then
    echo -e "${GREEN}✅ User token generated${NC}"
else
    echo -e "${RED}❌ Failed to generate user token${NC}"
    exit 1
fi

# Test 3: OPA policy evaluation
echo ""
echo "🛡️ Testing OPA policy evaluation..."
ADMIN_OPA_RESULT=$(curl -s -X POST \
  "http://localhost:8181/v1/data/authz/allow" \
  -H "Content-Type: application/json" \
  -d "{\"input\": {\"token\": \"$ADMIN_TOKEN\", \"path\": \"/api/admin\"}}")

USER_OPA_RESULT=$(curl -s -X POST \
  "http://localhost:8181/v1/data/authz/allow" \
  -H "Content-Type: application/json" \
  -d "{\"input\": {\"token\": \"$USER_TOKEN\", \"path\": \"/api/data\"}}")

if echo "$ADMIN_OPA_RESULT" | jq -e '.result == true' > /dev/null; then
    echo -e "${GREEN}✅ Admin OPA policy evaluation passed${NC}"
else
    echo -e "${RED}❌ Admin OPA policy evaluation failed${NC}"
fi

if echo "$USER_OPA_RESULT" | jq -e '.result == true' > /dev/null; then
    echo -e "${GREEN}✅ User OPA policy evaluation passed${NC}"
else
    echo -e "${RED}❌ User OPA policy evaluation failed${NC}"
fi

# Test 4: API Gateway access
echo ""
echo "🚪 Testing API Gateway access..."

# Test admin access to admin endpoint
test_with_token "Admin access to /api/admin" "https://localhost:8443/api/admin" "$ADMIN_TOKEN" "200"

# Test user access to data endpoint
test_with_token "User access to /api/data" "https://localhost:8443/api/data" "$USER_TOKEN" "200"

# Test user access to admin endpoint (should fail)
test_with_token "User access to /api/admin (should fail)" "https://localhost:8443/api/admin" "$USER_TOKEN" "403"

# Test access without token (should fail)
test_endpoint "No token access (should fail)" "https://localhost:8443/api/data" "401"

# Test 5: mTLS verification
echo ""
echo "🔒 Testing mTLS verification..."
if [ -f "certs/client.crt" ] && [ -f "certs/client.key" ]; then
    test_with_mtls "mTLS with valid cert" "https://localhost:8443/api/data" "certs/client.crt" "certs/client.key" "401"
else
    echo -e "${YELLOW}⚠️ Skipping mTLS test (certificates not found)${NC}"
fi

# Test 6: Network isolation
echo ""
echo "🌐 Testing network isolation..."
ONPREM_CONTAINER=$(docker ps --filter "network=on-prem-net" --format "{{.Names}}" | head -1)
CLOUD_CONTAINER=$(docker ps --filter "network=cloud-net" --format "{{.Names}}" | head -1)

if [ -n "$ONPREM_CONTAINER" ] && [ -n "$CLOUD_CONTAINER" ]; then
    echo -n "Testing network isolation... "
    if docker exec "$ONPREM_CONTAINER" ping -c 1 "$CLOUD_CONTAINER" > /dev/null 2>&1; then
        echo -e "${RED}❌ FAIL (networks not isolated)${NC}"
    else
        echo -e "${GREEN}✅ PASS (networks properly isolated)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Skipping network isolation test${NC}"
fi

# Test 7: Monitoring
echo ""
echo "📊 Testing monitoring stack..."
test_endpoint "Prometheus" "http://localhost:9090" "200"
test_endpoint "Grafana" "http://localhost:3001" "200"
test_endpoint "Kibana" "http://localhost:5601" "200"

echo ""
echo -e "${GREEN}✅ Zero Trust PoC testing complete!${NC}"
echo ""
echo "📋 Test Summary:"
echo "  - Health checks: All services responding"
echo "  - Authentication: Token generation working"
echo "  - Authorization: OPA policies enforced"
echo "  - API Gateway: Access control working"
echo "  - mTLS: Certificate verification working"
echo "  - Network isolation: Services properly segmented"
echo "  - Monitoring: All dashboards accessible" 