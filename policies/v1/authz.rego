package authz

# Fetch Keycloak JWKS
jwt_keys := http.send({
  "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
  "method": "GET"
}).body.keys

# Decode and verify JWT
decoded := io.jwt.decode(input.token)
verified := io.jwt.verify(decoded, jwt_keys)

# Policy: Allow if JWT valid + role check
allow if {
  verified
  decoded.payload.iss == "http://keycloak:8080/realms/zero-trust"
  decoded.payload.aud == "myapp"
  decoded.payload.preferred_username == "alice"  # Check username claim
  decoded.payload.role == "admin"  # Add role claim in Keycloak
}
