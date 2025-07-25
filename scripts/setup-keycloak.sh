#!/bin/bash
# scripts/setup-keycloak.sh

set -e

echo "========================================"
echo "Setting up Keycloak realm and users..."
echo "========================================"

# Wait for Keycloak to be ready
echo "----------------------------------------"
echo "Waiting for Keycloak to be ready..."
echo "----------------------------------------"
until curl -s http://localhost:8080/health > /dev/null; do
    sleep 5
done

# Get admin token
echo "----------------------------------------"
echo "Getting admin token..."
echo "----------------------------------------"
ADMIN_TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=securepassword" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin token"
    exit 1
fi

# Print first 9 characters of the admin token for verification
echo "Admin token (first 9 chars): ${ADMIN_TOKEN:0:9}"

# Handle master realm admin user - make it permanent if it's temporary
echo "----------------------------------------"
echo "Checking master realm admin user..."
echo "----------------------------------------"
MASTER_ADMIN_USER=$(curl -s "http://localhost:8080/admin/realms/master/users?username=admin" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if [ "$(echo "$MASTER_ADMIN_USER" | jq 'length')" -gt 0 ]; then
    MASTER_ADMIN_ID=$(echo "$MASTER_ADMIN_USER" | jq -r '.[0].id')
    MASTER_ADMIN_CREDENTIALS=$(curl -s "http://localhost:8080/admin/realms/master/users/$MASTER_ADMIN_ID/credentials" \
      -H "Authorization: Bearer $ADMIN_TOKEN")
    
    # Check if credentials are temporary
    TEMPORARY_CREDENTIALS=$(echo "$MASTER_ADMIN_CREDENTIALS" | jq -r '.[0].temporary // false')
    
    if [ "$TEMPORARY_CREDENTIALS" = "true" ]; then
        echo "Master realm admin user has temporary credentials. Making them permanent..."
        
        # Update the admin user to have permanent credentials
        curl -s -X PUT \
          "http://localhost:8080/admin/realms/master/users/$MASTER_ADMIN_ID/reset-password" \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{
            "type": "password",
            "value": "securepassword",
            "temporary": false
          }'
        
        echo "Master realm admin credentials made permanent."
    else
        echo "Master realm admin user already has permanent credentials."
    fi
else
    echo "Master realm admin user not found."
fi

# Create realm
echo "----------------------------------------"
echo "Creating realm..."
echo "----------------------------------------"
REALM_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "realm": "zero-trust",
    "enabled": true,
    "displayName": "Zero Trust"
  }' \
  "http://localhost:8080/admin/realms" 2>/dev/null)
if echo "$REALM_RESPONSE" | grep -q "errorMessage"; then
    echo "Realm already exists, continuing..."
else
    echo "Realm created successfully"
fi
echo ""

# Create client
# Always ensure correct redirect URIs and web origins
CLIENT_PAYLOAD='{
  "clientId": "myapp",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "secret": "EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa",
  "redirectUris": [
    "http://localhost:3000/*",
    "http://localhost:8082/*",
    "http://localhost:8082/auth/*"
  ],
  "webOrigins": [
    "http://localhost:3000",
    "http://localhost:8082"
  ],
  "publicClient": false,
  "protocol": "openid-connect",
  "directAccessGrantsEnabled": true
}'

# Check if client exists
CLIENT_RESPONSE=$(curl -s "http://localhost:8080/admin/realms/zero-trust/clients?clientId=myapp" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
CLIENT_ID=$(echo "$CLIENT_RESPONSE" | jq -r '.[0].id')

if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "null" ]; then
  echo "Creating client..."
  CLIENT_RESPONSE=$(curl -s -X POST \
    "http://localhost:8080/admin/realms/zero-trust/clients" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$CLIENT_PAYLOAD" 2>/dev/null)
  if echo "$CLIENT_RESPONSE" | grep -q "errorMessage"; then
      echo "Client already exists, continuing..."
  else
      echo "Client created successfully"
  fi
else
  echo "Updating client redirect URIs and web origins..."
  UPDATE_RESPONSE=$(curl -s -X PUT \
    "http://localhost:8080/admin/realms/zero-trust/clients/$CLIENT_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$CLIENT_PAYLOAD" 2>/dev/null)
  echo "Client updated successfully"
fi
echo ""

# Get client ID for further operations
echo "Fetching client ID for configuration..."
CLIENT_ID=$(curl -s "http://localhost:8080/admin/realms/zero-trust/clients?clientId=myapp" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" = "null" ]; then
    echo "Failed to get client ID. Client may not exist."
    exit 1
fi

echo "==============================="
echo "Client configuration complete!"
echo "Client ID: $CLIENT_ID"
echo "==============================="
echo ""

# Add audience mapper
echo "Adding audience mapper..."
MAPPER_RESPONSE=$(curl -s -X POST \
  "http://localhost:8080/admin/realms/zero-trust/clients/$CLIENT_ID/protocol-mappers/models" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "audience",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-audience-mapper",
    "config": {
      "included.client.audience": "myapp",
      "id.token.claim": "true",
      "access.token.claim": "true"
    }
  }' 2>/dev/null)
if echo "$MAPPER_RESPONSE" | grep -q "errorMessage"; then
    echo "Protocol mapper already exists, continuing..."
else
    echo "Protocol mapper created successfully"
fi
echo ""

# Create roles
ROLE_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/admin/realms/zero-trust/roles/user" -H "Authorization: Bearer $ADMIN_TOKEN")
if [ "$ROLE_EXISTS" = "200" ]; then
  echo "Role 'user' already exists, skipping creation."
else
  echo "Creating roles..."
  ROLE_ADMIN_RESPONSE=$(curl -s -X POST \
    "http://localhost:8080/admin/realms/zero-trust/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "admin", "description": "Administrator role"}')
  echo "$ROLE_ADMIN_RESPONSE"

  ROLE_USER_RESPONSE=$(curl -s -X POST \
    "http://localhost:8080/admin/realms/zero-trust/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "user", "description": "Regular user role"}')
  echo "$ROLE_USER_RESPONSE"
fi

# Create users
ADMIN_USER_EXISTS=$(curl -s "http://localhost:8080/admin/realms/zero-trust/users?username=admin" -H "Authorization: Bearer $ADMIN_TOKEN" | jq 'length')
if [ "$ADMIN_USER_EXISTS" -eq 0 ]; then
  echo "Creating admin user..."
  # Create admin user
  ADMIN_USER_RESPONSE=$(curl -s -X POST \
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
    }')
  echo "$ADMIN_USER_RESPONSE"

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
else
  echo "Admin user already exists, skipping creation."
fi

# Create 10 normal users
echo "----------------------------------------"
echo "Creating 10 normal users..."
echo "----------------------------------------"
for i in {1..10}; do
  USERNAME="user$i"
  USER_EXISTS=$(curl -s "http://localhost:8080/admin/realms/zero-trust/users?username=$USERNAME" -H "Authorization: Bearer $ADMIN_TOKEN" | jq 'length')
  
  if [ "$USER_EXISTS" -eq 0 ]; then
    echo "Creating user $USERNAME..."
    USER_RESPONSE=$(curl -s -X POST \
      "http://localhost:8080/admin/realms/zero-trust/users" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"username\": \"$USERNAME\",
        \"enabled\": true,
        \"email\": \"$USERNAME@example.com\",
        \"firstName\": \"User$i\",
        \"lastName\": \"Normal\",
        \"credentials\": [{
          \"type\": \"password\",
          \"value\": \"user${i}pass\",
          \"temporary\": false
        }]
      }")
    echo "$USER_RESPONSE"

    # Get user ID
    USER_ID=$(curl -s \
      "http://localhost:8080/admin/realms/zero-trust/users?username=$USERNAME" \
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
  else
    echo "User $USERNAME already exists, skipping creation."
  fi
done

# Create users file for traffic simulation
echo "----------------------------------------"
echo "Creating users file for traffic simulation..."
echo "----------------------------------------"
USERS_FILE="/tmp/simulation_users.json"
echo '{"users":[' > "$USERS_FILE"

# Add admin user
echo '"admin:adminpass"' >> "$USERS_FILE"

# Add normal users
for i in {1..10}; do
  echo ',"user'$i':user'$i'pass"' >> "$USERS_FILE"
done

echo ']}' >> "$USERS_FILE"

echo "========================================"
echo "Keycloak setup complete!"
echo "========================================"
echo ""
echo "----------------------------------------"
echo "Users created:"
echo "----------------------------------------"
echo "  - admin/adminpass (admin role)"
echo "  - user1/user1pass (user role)"
echo "  - user2/user2pass (user role)"
echo "  - user3/user3pass (user role)"
echo "  - user4/user4pass (user role)"
echo "  - user5/user5pass (user role)"
echo "  - user6/user6pass (user role)"
echo "  - user7/user7pass (user role)"
echo "  - user8/user8pass (user role)"
echo "  - user9/user9pass (user role)"
echo "  - user10/user10pass (user role)"
echo ""
echo "----------------------------------------"
echo "Users file created: $USERS_FILE"
echo "----------------------------------------" 