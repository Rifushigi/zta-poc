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
    
    echo -n "Testing $name... "
    
    # Determine if we need to use HTTPS
    local curl_opts=""
    if [[ "$url" == https://* ]]; then
        curl_opts="-k"
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" $curl_opts "$url")
    
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

# Wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local url="$2"
    local max_attempts="${3:-30}"
    
    echo "⏳ Waiting for $service_name to be ready..."
    local attempts=0
    
    # Determine if we need to use HTTPS
    local curl_opts=""
    if [[ "$url" == https://* ]]; then
        curl_opts="-k"
    fi
    
    until curl -s $curl_opts "$url" > /dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ $attempts -ge $max_attempts ]; then
            echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
            return 1
        fi
        sleep 2
    done
    echo -e "${GREEN}✅ $service_name is ready${NC}"
}

# Get token from Keycloak
get_token() {
    local username="$1"
    local password="$2"
    local client_id="${3:-myapp}"
    local client_secret="${4:-EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa}"
    
    local token=$(curl -s -X POST \
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
        echo -e "${RED}❌ Failed to get token for $username${NC}" >&2
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
    local trace_url="http://localhost:8181/v1/data/authz/trace"
    local jwt_decoded_url="http://localhost:8181/v1/data/authz/jwt_decoded"
    local jwt_header_debug_url="http://localhost:8181/v1/data/authz/jwt_header_debug"
    local jwt_claims_debug_url="http://localhost:8181/v1/data/authz/jwt_claims_debug"
    local jwks_debug_url="http://localhost:8181/v1/data/authz/jwks_debug"
    local key_matching_debug_url="http://localhost:8181/v1/data/authz/key_matching_debug"
    local jwt_debug_url="http://localhost:8181/v1/data/authz/jwt_debug"
    local input_echo_url="http://localhost:8181/v1/data/authz/input_echo"
    local debug_jwt_verified_url="http://localhost:8181/v1/data/authz/debug_jwt_verified"
    local valid_issuer_debug_url="http://localhost:8181/v1/data/authz/valid_issuer_debug"
    local valid_audience_debug_url="http://localhost:8181/v1/data/authz/valid_audience_debug"
    local token_not_expired_debug_url="http://localhost:8181/v1/data/authz/token_not_expired_debug"
    local token_not_before_debug_url="http://localhost:8181/v1/data/authz/token_not_before_debug"
    local jwt_signature_valid_debug_url="http://localhost:8181/v1/data/authz/jwt_signature_valid_debug"
    local jwt_verified_debug_url="http://localhost:8181/v1/data/authz/jwt_verified_debug"
    local jwt_signature_debug_url="http://localhost:8181/v1/data/authz/jwt_signature_debug"
    local jwt_signature_verification_debug_url="http://localhost:8181/v1/data/authz/jwt_signature_verification_debug"
    local curl_opts=""

    # Use jq to build the JSON safely
    local input_json
    input_json=$(jq -n --arg token "$token" --arg path "$path" '{input: {token: $token, path: $path}}')

    local result=$(curl -s $curl_opts -X POST \
      "$opa_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local trace=$(curl -s $curl_opts -X POST \
      "$trace_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_decoded=$(curl -s $curl_opts -X POST \
      "$jwt_decoded_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_header_debug=$(curl -s $curl_opts -X POST \
      "$jwt_header_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_claims_debug=$(curl -s $curl_opts -X POST \
      "$jwt_claims_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwks_debug=$(curl -s $curl_opts -X POST \
      "$jwks_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local key_matching_debug=$(curl -s $curl_opts -X POST \
      "$key_matching_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_debug=$(curl -s $curl_opts -X POST \
      "$jwt_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local input_echo=$(curl -s $curl_opts -X POST \
      "$input_echo_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local debug_jwt_verified=$(curl -s $curl_opts -X POST \
      "$debug_jwt_verified_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local valid_issuer_debug=$(curl -s $curl_opts -X POST \
      "$valid_issuer_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local valid_audience_debug=$(curl -s $curl_opts -X POST \
      "$valid_audience_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local token_not_expired_debug=$(curl -s $curl_opts -X POST \
      "$token_not_expired_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local token_not_before_debug=$(curl -s $curl_opts -X POST \
      "$token_not_before_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_signature_valid_debug=$(curl -s $curl_opts -X POST \
      "$jwt_signature_valid_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_verified_debug=$(curl -s $curl_opts -X POST \
      "$jwt_verified_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_signature_debug=$(curl -s $curl_opts -X POST \
      "$jwt_signature_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    local jwt_signature_verification_debug=$(curl -s $curl_opts -X POST \
      "$jwt_signature_verification_debug_url" \
      -H "Content-Type: application/json" \
      -d "$input_json")

    echo "\n--- OPA Policy Debug ---"
    echo "Input:"
    echo "$input_json" | jq
    echo "\nAllow result: $result"
    echo "\nDecoded JWT (jwt_decoded):"
    echo "$jwt_decoded" | jq
    echo "\nJWT Header Debug (jwt_header_debug):"
    echo "$jwt_header_debug" | jq
    echo "\nJWT Claims Debug (jwt_claims_debug):"
    echo "$jwt_claims_debug" | jq
    echo "\nJWKS Debug (jwks_debug):"
    echo "$jwks_debug" | jq
    echo "\nKey Matching Debug (key_matching_debug):"
    echo "$key_matching_debug" | jq
    echo "\nJWT Debug (jwt_debug):"
    echo "$jwt_debug" | jq
    echo "\nOPA Trace (trace):"
    echo "$trace" | jq
    echo "\nInput Echo (input_echo):"
    echo "$input_echo" | jq
    echo "\nDebug JWT Verified (debug_jwt_verified):"
    echo "$debug_jwt_verified" | jq
    echo "\nValid Issuer Debug (valid_issuer_debug):"
    echo "$valid_issuer_debug" | jq
    echo "\nValid Audience Debug (valid_audience_debug):"
    echo "$valid_audience_debug" | jq
    echo "\nToken Not Expired Debug (token_not_expired_debug):"
    echo "$token_not_expired_debug" | jq
    echo "\nToken Not Before Debug (token_not_before_debug):"
    echo "$token_not_before_debug" | jq
    echo "\nJWT Signature Valid Debug (jwt_signature_valid_debug):"
    echo "$jwt_signature_valid_debug" | jq
    echo "\nJWT Verified Debug (jwt_verified_debug):"
    echo "$jwt_verified_debug" | jq
    echo "\nJWT Signature Debug (jwt_signature_debug):"
    echo "$jwt_signature_debug" | jq
    echo "\nJWT Signature Verification Debug (jwt_signature_verification_debug):"
    echo "$jwt_signature_verification_debug" | jq
    echo "-----------------------\n"

    if echo "$result" | jq -e ".result == $expected_result" > /dev/null; then
        echo -e "${GREEN}✅ OPA policy evaluation passed${NC}"
        return 0
    else
        echo -e "${RED}❌ OPA policy evaluation failed${NC}"
        echo "DEBUG: OPA response: $result" >&2
        return 1
    fi
} 