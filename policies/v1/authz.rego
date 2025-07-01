package authz

import input

default allow = false

# Fetch JWKS
jwks_resp := http.send({
  "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
  "method": "GET"
})

jwt_keys := jwks_resp.body.keys if {
    jwks_resp.status_code == 200
}

debug_jwks = jwks_resp

# Decode and verify JWT
jwt_decoded := io.jwt.decode_verify(
    input.token,
{
    "cert": jwt_keys,
    "alg": "RS256",
    "iss": "http://localhost:8080/realms/zero-trust"
})

# Extract verification status and claims
jwt_verified := jwt_decoded[0]
jwt_claims := jwt_decoded[2]

# Define user_roles globally so it's accessible for other rules like debug_info
# This requires input.token to be present and jwt_decoded to succeed
user_roles := jwt_claims.realm_access.roles if { input.token }

valid_audience_combined if {
    is_string(jwt_claims.aud);
    jwt_claims.aud == "myapp"
}

valid_audience_combined if {
    is_string(jwt_claims.aud);
    jwt_claims.aud == "account"
}

valid_audience_combined if {
    is_array(jwt_claims.aud);
    some i;
    jwt_claims.aud[i] == "myapp"
}

valid_audience_combined if {
    is_array(jwt_claims.aud);
    some i;
    jwt_claims.aud[i] == "account"
}


# Check roles for path
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

# Main allow rule
allow if {
    jwt_verified == true
    valid_audience_combined # Use the combined audience check
    # user_roles is now global if input.token exists, no need to redefine here
    has_required_role(input.path, user_roles)
}

# Debug info rule for troubleshooting
debug_info = {
    "jwt_verified": jwt_verified,
    "valid_audience": valid_audience_combined, # Use the combined audience check
    "user_roles": user_roles,
    "input_path": input.path,
    "has_required_role": has_required_role(input.path, user_roles)
} if {
    # This 'if' block ensures that the debug_info is only computed if the necessary
    # variables (like jwt_decoded, user_roles) can be resolved.
    # It also ensures that 'user_roles' is bound before used within this rule.
    true # A simple true condition ensures the rule body is evaluated if possible
}

# Minimal debug rule for jwt_decoded
debug_decoded = jwt_decoded

debug_all = {
  "jwt_decoded": jwt_decoded,
  "jwt_verified": jwt_verified,
  "jwt_claims": jwt_claims,
  "user_roles": user_roles,
  "valid_audience_combined": valid_audience_combined,
  "input_path": input.path,
  "has_required_role": has_required_role(input.path, user_roles)
}

input_token_debug = input.token