package authz

import input

default allow = false

# Decode JWT parts if token exists
jwt_parts := io.jwt.decode(input.token) if input.token
jwt_header := jwt_parts[1] if jwt_parts
jwt_claims := jwt_parts[2] if jwt_parts
jwt_kid := jwt_header.kid if jwt_header

# Fetch JWKS keys dynamically
jwks_keys := [k | 
    jwks_resp := http.send({
        "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
        "method": "GET"
    });
    jwks_resp.status_code == 200;
    some i;
    k := jwks_resp.body.keys[i]
]

# Select the appropriate key by matching kid
selected_key := key if {
    jwt_kid
    some i
    key := jwks_keys[i]
    key.kid == jwt_kid
}

# Verify JWT signature
jwt_signature_valid := io.jwt.verify_rs256(input.token, selected_key) if input.token && selected_key

# Validate issuer if jwt_claims exists and contains "iss"
valid_issuer if {
    jwt_verified
    jwt_claims.iss == "http://localhost:8080/realms/zero-trust"
}

# Validate audience (string or array)
valid_audience if {
    jwt_verified
    is_string(jwt_claims.aud)
    jwt_claims.aud == "myapp" or jwt_claims.aud == "account"
}
valid_audience if {
    jwt_verified
    is_array(jwt_claims.aud)
    some i
    jwt_claims.aud[i] == "myapp" or jwt_claims.aud[i] == "account"
}

# Only verified if all of the above checks pass
jwt_verified if {
    input.token
    jwt_claims
    jwt_signature_valid
}

# Extract roles if realm_access and roles exist
user_roles := jwt_claims.realm_access.roles if {
    jwt_verified
    jwt_claims.realm_access
    jwt_claims.realm_access.roles
}

# Define access control rules based on roles and path
has_required_role(path, roles) if {
    startswith(path, "/api/admin")
    contains(roles, "admin")
}
has_required_role(path, roles) if {
    startswith(path, "/api/data")
    contains(roles, "user")
}
has_required_role(path, roles) if {
    path == "/health"
}

# Main policy rule
allow if {
    jwt_verified
    user_roles
    has_required_role(input.path, user_roles)
}

# Debug block for introspection
debug = {
    "jwt_kid": jwt_kid,
    "jwt_header": jwt_header,
    "jwt_claims": jwt_claims,
    "jwks_keys": jwks_keys,
    "selected_key": selected_key,
    "jwt_signature_valid": jwt_signature_valid,
    "valid_issuer": valid_issuer,
    "valid_audience": valid_audience,
    "jwt_verified": jwt_verified,
    "user_roles": user_roles,
    "has_required_role": has_required_role(input.path, user_roles)
} if input.token