package debug

import input

# Test JWT verification without audience check
test_jwt_no_audience if {
  jwt_keys := http.send({
    "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
    "method": "GET"
  }).body.keys

  jwt_decoded := io.jwt.decode_verify(
    input.token,
    {
      "cert": jwt_keys,
      "alg": "RS256",
      "iss": "http://localhost:8080/realms/zero-trust"
    }
  )

  jwt_verified := jwt_decoded[0]
  jwt_claims := jwt_decoded[2]

  jwt_verified == true
  jwt_claims.realm_access.roles[_] == "admin"
}

# Test with audience check
test_jwt_with_audience if {
  jwt_keys := http.send({
    "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
    "method": "GET"
  }).body.keys

  jwt_decoded := io.jwt.decode_verify(
    input.token,
    {
      "cert": jwt_keys,
      "alg": "RS256",
      "iss": "http://localhost:8080/realms/zero-trust",
      "aud": ["account", "myapp"]
    }
  )

  jwt_verified := jwt_decoded[0]
  jwt_claims := jwt_decoded[2]

  jwt_verified == true
  jwt_claims.realm_access.roles[_] == "admin"
} 