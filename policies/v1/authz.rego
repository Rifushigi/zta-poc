package authz

# Fetch Keycloak JWKS
jwt_keys := http.send({
  "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
  "method": "GET"
}).body.keys

# Decode and verify JWT
decoded := io.jwt.decode(input.token)
verified := io.jwt.verify(decoded, jwt_keys)

# Extract user information from JWT
user_info := {
  "username": decoded.payload.preferred_username,
  "roles": decoded.payload.realm_access.roles,
  "email": decoded.payload.email
}

# Policy: Allow if JWT valid + role check
allow if {
  verified
  decoded.payload.iss == "http://keycloak:8080/realms/zero-trust"
  decoded.payload.aud == "myapp"
  has_required_role(input.path, user_info.roles)
}

# Check if user has required role for the path
has_required_role(path, roles) {
  # Admin endpoints require admin role
  startswith(path, "/api/admin")
  contains(roles, "admin")
}

has_required_role(path, roles) {
  # Regular API endpoints require user role
  startswith(path, "/api/data")
  contains(roles, "user")
}

has_required_role(path, roles) {
  # Health check doesn't require specific role
  path == "/health"
}

# Default deny
allow = false
