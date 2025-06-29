package authz

import input

# Fetch JWKS
jwt_keys := http.send({
  "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
  "method": "GET"
}).body.keys

# Decode and verify JWT
jwt_decoded := io.jwt.decode_verify(
  input.token,
  {
    "cert": jwt_keys,
    "alg": "RS256",
    "iss": "http://keycloak:8080/realms/zero-trust",
    "aud": ["myapp"]
  }
)

# Extract verification status and claims
jwt_verified := jwt_decoded[0]
jwt_header := jwt_decoded[1]
jwt_claims := jwt_decoded[2]

# Main allow rule: ensure token is verified, then check roles
allow if {
  jwt_verified == true
  user_roles := jwt_claims.realm_access.roles
  has_required_role(input.path, user_roles)
}

# Role-based checks
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

default allow = false
