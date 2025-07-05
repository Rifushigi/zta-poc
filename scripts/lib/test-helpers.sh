#!/bin/bash
# scripts/lib/test-helpers.sh
# Common test functions and utilities for test scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function for basic endpoints
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local should_fail="${4:-false}"
    
    echo -n "Testing $name... "
    
    # Determine if we need to use HTTPS
    local curl_opts=""
    if [[ "$url" == https://* ]]; then
        curl_opts="-k"
    fi
    
    response=$(curl -s -m 30 -o /dev/null -w "%{http_code}" $curl_opts "$url")
    
    if [ "$response" = "$expected_status" ]; then
        if [ "$should_fail" = "true" ]; then
            echo -e "${GREEN}PASS (correctly denied)${NC}"
        else
            echo -e "${GREEN}PASS${NC}"
        fi
        return 0
    else
        if [ "$should_fail" = "true" ]; then
            echo -e "${RED}FAIL (got $response, expected $expected_status)${NC}"
        else
            echo -e "${RED}FAIL (got $response, expected $expected_status)${NC}"
        fi
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
    local should_fail="${7:-false}"
    
    echo -n "Testing $name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -m 30 -o /dev/null -w "%{http_code}" -X "$method" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -m 30 -o /dev/null -w "%{http_code}" -X "$method" -H "Authorization: Bearer $token" "$url")
    fi
    
    if [ "$response" = "$expected_status" ]; then
        if [ "$should_fail" = "true" ]; then
            echo -e "${GREEN}PASS (correctly denied)${NC}"
        else
            echo -e "${GREEN}PASS${NC}"
        fi
        return 0
    else
        if [ "$should_fail" = "true" ]; then
            echo -e "${RED}FAIL (got $response, expected $expected_status)${NC}"
        else
            echo -e "${RED}FAIL (got $response, expected $expected_status)${NC}"
        fi
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
    if curl -s -m 30 -o /dev/null -w "%{http_code}" --cert "$cert" --key "$key" --cacert certs/ca.crt "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

# Wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local url="$2"
    local max_attempts="${3:-30}"
    
    echo "Waiting for $service_name to be ready..."
    local attempts=0
    
    # Determine if we need to use HTTPS
    local curl_opts=""
    if [[ "$url" == https://* ]]; then
        curl_opts="-k"
    fi
    
    until curl -s -m 10 $curl_opts "$url" > /dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ $attempts -ge $max_attempts ]; then
            echo -e "${RED}$service_name failed to start after $max_attempts attempts${NC}"
            return 1
        fi
        sleep 2
    done
    echo -e "${GREEN}$service_name is ready${NC}"
}

# Get token from Keycloak
get_token() {
    local username="$1"
    local password="$2"
    local client_id="${3:-myapp}"
    local client_secret="${4:-EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa}"
    
    local token=$(curl -s -m 30 -X POST \
      "http://localhost:8080/realms/zero-trust/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=$client_id" \
      -d "client_secret=$client_secret" \
      -d "username=$username" \
      -d "password=$password" \
      -d "grant_type=password" | jq -r '.access_token')
    
    if [ "$token" != "null" ] && [ -n "$token" ]; then
        echo "$token"
        return 0
    else
        echo -e "${RED}Failed to get token for $username${NC}" >&2
        return 1
    fi
}

# Test OPA policy evaluation
test_opa_policy() {
    local token="$1"
    local path="$2"
    local expected_result="$3"
    
    # Always use HTTP for OPA
    local opa_url="http://localhost:8181/v1/data/authz/allow"
    local curl_opts=""

    # Use jq to build the JSON safely
    local input_json
    input_json=$(jq -n --arg token "$token" --arg path "$path" '{input: {token: $token, path: $path}}')

    local result=$(curl -s -m 30 $curl_opts -X POST \
      "$opa_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    if echo "$result" | jq -e ".result == $expected_result" > /dev/null; then
        echo -e "${GREEN}OPA policy evaluation passed${NC}"
        return 0
    else
        echo -e "${RED}OPA policy evaluation failed${NC}"
        echo "DEBUG: OPA response: $result" >&2
        return 1
    fi
} 