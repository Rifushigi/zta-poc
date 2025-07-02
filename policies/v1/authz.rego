package authz

import input

default allow = false

jwks_resp := http.send({
  "url": "http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs",
  "method": "GET"
})
jwks_keys := jwks_resp.body.keys if jwks_resp.status_code == 200

jwt_parts := io.jwt.decode(input.token)
jwt_header := jwt_parts[1]
jwt_claims := jwt_parts[2]
jwt_kid := jwt_header.kid

selected_key := key if {
  some i
  key := jwks_keys[i]
  key.kid == jwt_kid
}

jwt_signature_valid := io.jwt.verify_rs256(input.token, selected_key)

valid_issuer := jwt_claims.iss == "http://localhost:8080/realms/zero-trust"

valid_audience if {
  is_string(jwt_claims.aud)
  jwt_claims.aud == "myapp"
}
valid_audience if {
  is_string(jwt_claims.aud)
  jwt_claims.aud == "account"
}
valid_audience if {
  is_array(jwt_claims.aud)
  some i
  jwt_claims.aud[i] == "myapp"
}
valid_audience if {
  is_array(jwt_claims.aud)
  some i
  jwt_claims.aud[i] == "account"
}

jwt_verified if {
  jwt_signature_valid
  valid_issuer
  valid_audience
}

user_roles := jwt_claims.realm_access.roles if jwt_verified

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

allow if {
  jwt_verified
  has_required_role(input.path, user_roles)
}

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
}