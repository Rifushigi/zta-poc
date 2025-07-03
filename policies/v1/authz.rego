package authz

default allow := false

# Always allow health check
is_health_check if {
    input.path == "/health"
}

# Main allow rule
allow if is_health_check
allow if user_is_admin  
allow if user_is_user


# Helper function to safely extract claim fields
get_claim(claims, key, def) = val if {
    is_object(claims)
    val := object.get(claims, key, def)
}
get_claim(claims, key, def) = def if {
    not is_object(claims)
}

# Dynamically fetch JWKS JSON
jwks_resp := http.send({
    "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
    "method": "GET",
    "timeout": "10s"
})

# Verify signature using JWKS JSON
jwt_signature_valid if {
    input.token
    jwks_resp.status_code == 200
    io.jwt.verify_rs256(input.token, jwks_resp.body)
}

# Ensure issuer matches expected value, using get_claim for field access
valid_issuer if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]  # Claims/payload is index 1
    iss := get_claim(jwt_claims, "iss", "")
    iss == "http://keycloak:8080/realms/zero-trust"
}

# Audience check for string or array type, using get_claim for field access
valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
    aud := get_claim(jwt_claims, "aud", "")
    is_string(aud)
    aud in {"myapp", "account"}  # More concise way to check multiple values
}

valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
    aud := get_claim(jwt_claims, "aud", [])
    is_array(aud)
    # Check if any audience matches our required audiences
    count([a | a := aud[_]; a in {"myapp", "account"}]) > 0
}

# Token expiration check
token_not_expired if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
    exp := get_claim(jwt_claims, "exp", 0)
    exp > time.now_ns() / 1000000000  # Convert nanoseconds to seconds
}

# Token not before check
token_not_before if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
    nbf := get_claim(jwt_claims, "nbf", 0)
    nbf <= time.now_ns() / 1000000000
}

# Combine JWT verification conditions
jwt_verified if {
    jwt_signature_valid
    valid_issuer
    valid_audience
    token_not_expired
    token_not_before
}

# Extract user roles from token if present, using get_claim for field access
user_roles[role] if {
    
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
    realm_access := get_claim(jwt_claims, "realm_access", {})
    is_object(realm_access)
    roles := get_claim(realm_access, "roles", [])
    is_array(roles)
    role := roles[_]
}

# Admin access: allow if user has 'admin' role
user_is_admin if {
    user_roles["admin"]
}

# User access: allow if user has 'user' role and path matches
user_is_user if {
    user_roles["user"]
    startswith(input.path, "/api/data")
}

# Debug: JWT parts count
jwt_parts_count := count(io.jwt.decode(input.token)) if input.token
jwt_parts_count := 0 if not input.token

# Enhanced debug trace for testing
trace := {
    "input": input,
    "jwt_parts_count": jwt_parts_count,
    "jwt_signature_valid": jwt_signature_valid,
    "valid_issuer": valid_issuer,
    "valid_audience": valid_audience,
    "token_not_expired": token_not_expired,
    "token_not_before": token_not_before,
    "jwt_verified": jwt_verified,
    "user_roles": [r | r := user_roles[_]],
    "user_is_admin": user_is_admin,
    "user_is_user": user_is_user,
    "is_health_check": is_health_check,
    "jwks_keys_count": count(jwks_resp.body.keys),
    "allow": allow
}

# Debug: decode JWT with error handling
jwt_decoded := result if {
    input.token
    result := io.jwt.decode(input.token)
}

# Debug: JWT header analysis
jwt_header_debug := {
    "header": jwt_parts[0],
    "kid": jwt_parts[0].kid
} if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
}

# Debug: JWT claims analysis
jwt_claims_debug := {
    "claims": jwt_claims,
    "iss": get_claim(jwt_claims, "iss", "<missing>"),
    "aud": get_claim(jwt_claims, "aud", "<missing>"),
    "exp": get_claim(jwt_claims, "exp", "<missing>"),
    "nbf": get_claim(jwt_claims, "nbf", "<missing>"),
    "realm_access": get_claim(jwt_claims, "realm_access", "<missing>")
} if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_claims := jwt_parts[1]
}

# Debug: JWKS analysis
jwks_debug := {
    "jwks_response_status": jwks_resp.status_code,
    "jwks_keys_count": count(jwks_resp.body.keys),
    "jwks_kids": [k.kid | k := jwks_resp.body.keys[_]]
} if {
    jwks_resp := http.send({
        "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
        "method": "GET",
        "timeout": "10s"
    })
}

# Debug: Key matching analysis
key_matching_debug := {
    "jwt_kid": jwt_kid,
    "available_kids": [k.kid | k := jwks_resp.body.keys[_]],
    "key_found": count([k | k := jwks_resp.body.keys[_]; k.kid == jwt_kid]) > 0
} if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    jwt_header := jwt_parts[0]
    jwt_kid := jwt_header.kid
}

# Minimal debug rule: always return input for troubleshooting
input_echo := input

# Debug: show all verification steps
jwt_debug := {
    "jwt_signature_valid": jwt_signature_valid,
    "valid_issuer": valid_issuer,
    "valid_audience": valid_audience,
    "token_not_expired": token_not_expired,
    "token_not_before": token_not_before,
    "jwt_verified": jwt_verified,
    "user_roles": [r | r := user_roles[_]],
    "user_is_admin": user_is_admin,
    "user_is_user": user_is_user,
    "allow": allow
}

jwt_signature_debug := {
    "has_token": input.token != "",
    "jwt_parts_valid": count(io.jwt.decode(input.token)) == 3,
    "jwt_kid": jwt_parts[0].kid,
    "jwks_keys_available": count(jwks_resp.body.keys),
    "available_kids": [k.kid | k := jwks_resp.body.keys[_]],
    "matching_keys_found": count([k | k := jwks_resp.body.keys[_]; k.kid == jwt_parts[0].kid])
} if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
}

# Debug the actual signature verification step
jwt_signature_verification_debug := {
    "jwt_kid": jwt_parts[0].kid,
    "matching_key_found": count([k | k := jwks_resp.body.keys[_]; k.kid == jwt_parts[0].kid]) > 0,
    "matching_key_details": matching_key,
    "signature_verification_result": io.jwt.verify_rs256(input.token, matching_key),
    "key_type": matching_key.kty,
    "key_use": matching_key.use,
    "key_algorithm": matching_key.alg
} if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    count(jwt_parts) == 3
    matching_key := [k | k := jwks_resp.body.keys[_]; k.kid == jwt_parts[0].kid][0]
}

valid_issuer_debug = valid_issuer
valid_audience_debug = valid_audience
token_not_expired_debug = token_not_expired
token_not_before_debug = token_not_before
jwt_signature_valid_debug = jwt_signature_valid
jwt_verified_debug = jwt_verified