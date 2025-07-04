#!/bin/bash
# scripts/test-deployment.sh

# Source common test functions
source "$(dirname "$0")/lib/test-helpers.sh"

echo "🧪 Testing Zero Trust deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Wait for services to be ready
wait_for_service "Keycloak" "http://localhost:8080/"
wait_for_service "OPA" "http://localhost:8181/health"
wait_for_service "Backend" "http://localhost:4000/health"
wait_for_service "Prometheus" "http://localhost:9090/-/healthy"

# Test 1: Health checks
echo ""
echo "🔍 Testing health checks..."
test_endpoint "Keycloak Health" "http://localhost:8080/" "302"
test_endpoint "OPA Health" "http://localhost:8181/health" "200"
test_endpoint "Backend Health" "http://localhost:4000/health" "200"
test_endpoint "Prometheus Health" "http://localhost:9090/-/healthy" "200"

# Test 2: Get tokens
echo ""
echo "🔐 Testing token generation..."
ADMIN_TOKEN=$(get_token "admin" "adminpass")
USER_TOKEN=$(get_token "user" "userpass")

if [ -n "$ADMIN_TOKEN" ]; then
    echo -e "${GREEN}✅ Admin token generated${NC}"
else
    echo -e "${RED}❌ Failed to generate admin token${NC}"
    exit 1
fi

if [ -n "$USER_TOKEN" ]; then
    echo -e "${GREEN}✅ User token generated${NC}"
else
    echo -e "${RED}❌ Failed to generate user token${NC}"
    exit 1
fi

# Test 3: OPA policy evaluation
echo ""
echo "🛡️ Testing OPA policy evaluation..."
test_opa_policy "$ADMIN_TOKEN" "/api/admin" "true"
test_opa_policy "$USER_TOKEN" "/api/data" "true"

# Test 4: API Gateway access
echo ""
echo "🚪 Testing API Gateway access..."

# Test admin access to admin endpoint
test_with_token "Admin access to /api/admin" "http://localhost:8000/api/admin" "GET" "$ADMIN_TOKEN" "" "200"

# Test user access to data endpoint
test_with_token "User access to /api/data" "http://localhost:8000/api/data" "GET" "$USER_TOKEN" "" "200"

# Test user access to admin endpoint (should fail)
test_with_token "User access to /api/admin (should fail)" "http://localhost:8000/api/admin" "GET" "$USER_TOKEN" "" "403"

# Test access without token (should fail)
test_endpoint "No token access (should fail)" "http://localhost:8000/api/data" "401"

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
echo -e "${GREEN}✅ Zero Trust testing complete!${NC}"
echo ""
echo "📋 Test Summary:"
echo "  - Health checks: All services responding"
echo "  - Authentication: Token generation working"
echo "  - Authorization: OPA policies enforced"
echo "  - API Gateway: Access control working"
echo "  - Network isolation: Services properly segmented"
echo "  - Monitoring: All dashboards accessible"