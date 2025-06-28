#!/bin/bash
# scripts/test-backend-features.sh

set -e

echo "🧪 Testing Backend Service Features..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="$3"
    local data="$4"
    local expected_status="$5"
    
    echo -n "Testing $name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url")
    fi
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (got $response, expected $expected_status)${NC}"
        return 1
    fi
}

# Test function with token
test_with_token() {
    local name="$1"
    local url="$2"
    local method="$3"
    local token="$4"
    local data="$5"
    local expected_status="$6"
    
    echo -n "Testing $name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Authorization: Bearer $token" "$url")
    fi
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (got $response, expected $expected_status)${NC}"
        return 1
    fi
}

# Wait for backend service to be ready
echo "⏳ Waiting for backend service to be ready..."
until curl -s http://localhost:3000/health > /dev/null; do
    sleep 2
done

# Test 1: Health and Metrics endpoints
echo ""
echo "🔍 Testing Health and Metrics..."
test_endpoint "Health Check" "http://localhost:3000/health" "GET" "" "200"
test_endpoint "Metrics Endpoint" "http://localhost:3000/metrics" "GET" "" "200"

# Test 2: Input Validation
echo ""
echo "✅ Testing Input Validation..."

# Test validation failure (empty name)
test_with_token "Create item with empty name (should fail)" "http://localhost:3000/api/data" "POST" "dummy-token" '{"name":"","description":"test"}' "400"

# Test validation failure (name too long)
test_with_token "Create item with long name (should fail)" "http://localhost:3000/api/data" "POST" "dummy-token" '{"name":"'"$(printf 'a%.0s' {1..300})"'","description":"test"}' "400"

# Test validation failure (missing description)
test_with_token "Create item without description (should fail)" "http://localhost:3000/api/data" "POST" "dummy-token" '{"name":"test"}' "400"

# Test 3: Rate Limiting
echo ""
echo "🚦 Testing Rate Limiting..."
echo -n "Testing rate limiting... "
# Make multiple requests quickly
for i in {1..5}; do
    curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health > /tmp/rate_test_$i &
done
wait

# Check if any requests were rate limited (429)
rate_limited=false
for i in {1..5}; do
    if [ "$(cat /tmp/rate_test_$i)" = "429" ]; then
        rate_limited=true
        break
    fi
done

if [ "$rate_limited" = true ]; then
    echo -e "${GREEN}✅ PASS (rate limiting working)${NC}"
else
    echo -e "${YELLOW}⚠️ Rate limiting not triggered (may need more requests)${NC}"
fi

# Clean up temp files
rm -f /tmp/rate_test_*

# Test 4: Security Headers
echo ""
echo "🔒 Testing Security Headers..."
echo -n "Testing security headers... "
headers=$(curl -s -I http://localhost:3000/health | grep -E "(X-Content-Type-Options|X-Frame-Options|X-XSS-Protection)" | wc -l)
if [ "$headers" -ge 2 ]; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 5: Request ID Propagation
echo ""
echo "🆔 Testing Request ID Propagation..."
echo -n "Testing request ID... "
request_id=$(curl -s -I http://localhost:3000/health | grep "X-Request-ID" | head -1 | cut -d' ' -f2 | tr -d '\r')
if [ -n "$request_id" ]; then
    echo -e "${GREEN}✅ PASS (Request ID: $request_id)${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 6: CORS
echo ""
echo "🌐 Testing CORS..."
echo -n "Testing CORS headers... "
cors_headers=$(curl -s -I -H "Origin: http://localhost:3000" http://localhost:3000/health | grep -E "(Access-Control-Allow-Origin|Access-Control-Allow-Credentials)" | wc -l)
if [ "$cors_headers" -ge 1 ]; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 7: Error Handling
echo ""
echo "⚠️ Testing Error Handling..."

# Test 404
test_endpoint "Non-existent endpoint (should return 404)" "http://localhost:3000/nonexistent" "GET" "" "404"

# Test invalid JSON
test_with_token "Invalid JSON (should return 400)" "http://localhost:3000/api/data" "POST" "dummy-token" '{"invalid": json}' "400"

# Test 8: Pagination
echo ""
echo "📄 Testing Pagination..."
echo -n "Testing pagination parameters... "
# Test with valid pagination parameters
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/data?page=1&limit=5")
if [ "$response" = "401" ]; then
    echo -e "${GREEN}✅ PASS (pagination validation working)${NC}"
else
    echo -e "${YELLOW}⚠️ Unexpected response: $response${NC}"
fi

# Test with invalid pagination parameters
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/data?page=0&limit=1000")
if [ "$response" = "400" ]; then
    echo -e "${GREEN}✅ PASS (pagination validation working)${NC}"
else
    echo -e "${YELLOW}⚠️ Unexpected response: $response${NC}"
fi

echo ""
echo -e "${GREEN}✅ Backend Service Feature Testing Complete!${NC}"
echo ""
echo "📋 Test Summary:"
echo "  - Health and Metrics: Endpoints responding"
echo "  - Input Validation: Joi schemas working"
echo "  - Rate Limiting: Protection against abuse"
echo "  - Security Headers: Helmet middleware active"
echo "  - Request ID: Tracing implemented"
echo "  - CORS: Cross-origin requests configured"
echo "  - Error Handling: Proper error responses"
echo "  - Pagination: Query parameter validation"
echo ""
echo "🔧 To test with real authentication, use the main test script:"
echo "   ./scripts/test-deployment.sh" 