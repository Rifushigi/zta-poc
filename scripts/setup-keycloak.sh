#!/bin/bash
# scripts/setup-keycloak.sh

set -e

echo "🔑 Setting up Keycloak realm and users..."

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
until curl -s http://localhost:8080/health > /dev/null; do
    sleep 5
done

# Get admin token
echo "🔐 Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=securepassword" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

# Create realm
echo "🏛️ Creating realm..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "realm": "zero-trust",
    "enabled": true,
    "displayName": "Zero Trust"
  }' \
  "http://localhost:8080/admin/realms"

# Create client
echo "Creating client..."
curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "myapp",
    "enabled": true,
    "clientAuthenticatorType": "client-secret",
    "secret": "EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa",
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"],
    "publicClient": false,
    "protocol": "openid-connect"
  }'

# Create roles
echo "👥 Creating roles..."
curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/roles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "admin", "description": "Administrator role"}'

curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/roles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "user", "description": "Regular user role"}'

# Create users
echo "👤 Creating users..."

# Create admin user
curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "enabled": true,
    "email": "admin@example.com",
    "firstName": "Admin",
    "lastName": "User",
    "credentials": [{
      "type": "password",
      "value": "adminpass",
      "temporary": false
    }]
  }'

# Get admin user ID
ADMIN_USER_ID=$(curl -s \
  "http://localhost:8080/admin/realms/zero-trust/users?username=admin" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

# Assign admin role to admin user
ADMIN_ROLE_ID=$(curl -s \
  "http://localhost:8080/admin/realms/zero-trust/roles/admin" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')

curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/users/$ADMIN_USER_ID/role-mappings/realm" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\":\"$ADMIN_ROLE_ID\",\"name\":\"admin\"}]"

# Create regular user
curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user",
    "enabled": true,
    "email": "user@example.com",
    "firstName": "Regular",
    "lastName": "User",
    "credentials": [{
      "type": "password",
      "value": "userpass",
      "temporary": false
    }]
  }'

# Get user ID
USER_ID=$(curl -s \
  "http://localhost:8080/admin/realms/zero-trust/users?username=user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

# Assign user role
USER_ROLE_ID=$(curl -s \
  "http://localhost:8080/admin/realms/zero-trust/roles/user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')

curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/users/$USER_ID/role-mappings/realm" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\":\"$USER_ROLE_ID\",\"name\":\"user\"}]"

echo "✅ Keycloak setup complete!"
echo ""
echo "👥 Users created:"
echo "  - admin/adminpass (admin role)"
echo "  - user/userpass (user role)" 