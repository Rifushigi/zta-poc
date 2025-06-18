#!/bin/bash
# scripts/get_token.sh

CLIENT_ID=myapp
CLIENT_SECRET=EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa
USERNAME=rifushigi
PASSWORD=securepassword

TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/zero-trust/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "grant_type=password" | jq -r '.access_token')

echo "Your token: $TOKEN"

# Query OPA with the token
curl -X POST http://localhost:8181/v1/data/authz/allow \
  -H "Content-Type: application/json" \
  -d '{"input": {"token": "'"$TOKEN"'"}}'

# Expected response: {"result": true} if allowed