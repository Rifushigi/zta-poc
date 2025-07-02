package authz

default allow = false

# Helper function to safely extract claim fields
get_claim(claims, key, def) = val if {
    is_object(claims)
    val := object.get(claims, key, def)
}
get_claim(claims, key, def) = def if {
    not is_object(claims)
}

# Dynamically fetch JWKS keys
jwks_keys := [k |
    jwks_resp := http.send({
        "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
        "method": "GET"
    })
    jwks_resp.status_code == 200
    some i
    k := jwks_resp.body.keys[i]
]

# Select matching key by 'kid'
selected_key[kid] if {
    some i
    key := jwks_keys[i]
    kid := key.kid
}

# Verify signature using selected key
jwt_signature_valid if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_header := jwt_parts[1]
    jwt_kid := jwt_header.kid
    selected_key[jwt_kid]
    io.jwt.verify_rs256(input.token, [k | k := jwks_keys[_]; k.kid == jwt_kid][0])
}

# Ensure issuer matches expected value, using get_claim for field access
valid_issuer if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    iss := get_claim(jwt_claims, "iss", "")
    iss == "http://localhost:8080/realms/zero-trust"
}

# Audience check for string or array type, using get_claim for field access
valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    aud := get_claim(jwt_claims, "aud", "")
    is_string(aud)
    aud == "myapp"
}
valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    aud := get_claim(jwt_claims, "aud", "")
    is_string(aud)
    aud == "account"
}
valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    aud := get_claim(jwt_claims, "aud", [])
    is_array(aud)
    some i
    aud[i] == "myapp"
}
valid_audience if {
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    aud := get_claim(jwt_claims, "aud", [])
    is_array(aud)
    some i
    aud[i] == "account"
}

# Combine JWT verification conditions
jwt_verified if {
    jwt_signature_valid
    valid_issuer
    valid_audience
}

# Extract user roles from token if present, using get_claim for field access
user_roles[role] if {
    jwt_verified
    input.token
    jwt_parts := io.jwt.decode(input.token)
    is_array(jwt_parts)
    jwt_claims := jwt_parts[2]
    realm_access := get_claim(jwt_claims, "realm_access", {})
    is_object(realm_access)
    roles := get_claim(realm_access, "roles", [])
    is_array(roles)
    role := roles[_]
}

# Admin access: allow if user has 'admin' role
user_is_admin if {
    "admin" in user_roles
}

# User access: allow if user has 'user' role and path matches
user_is_user if {
    "user" in user_roles
    input.path
    startswith(input.path, "/api/data")
}

# Always allow health check
is_health_check if {
    input.path == "/health"
}

# Main allow rule
allow if is_health_check
allow if user_is_admin
allow if user_is_user

# Debug trace for testing
debug := {
    "jwks_keys": jwks_keys,
    "user_roles": [r | r := user_roles[_]],
    "is_health_check": is_health_check
} if input.token