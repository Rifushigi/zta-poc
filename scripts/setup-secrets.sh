#!/bin/bash
# scripts/setup-secrets.sh

set -e

echo "🔐 Setting up secrets for production deployment..."

SECRETS_DIR="secrets"
mkdir -p $SECRETS_DIR

# Generate random passwords
DB_USER="backend"
DB_PASSWORD=$(openssl rand -base64 32)
POSTGRES_USER="postgres"
POSTGRES_PASSWORD=$(openssl rand -base64 32)
KEYCLOAK_PASSWORD=$(openssl rand -base64 32)

# Create secret files
echo "$DB_USER" > $SECRETS_DIR/db_user.txt
echo "$DB_PASSWORD" > $SECRETS_DIR/db_password.txt
echo "$POSTGRES_USER" > $SECRETS_DIR/postgres_user.txt
echo "$POSTGRES_PASSWORD" > $SECRETS_DIR/postgres_password.txt
echo "$KEYCLOAK_PASSWORD" > $SECRETS_DIR/keycloak_admin_password.txt

# Set proper permissions
chmod 600 $SECRETS_DIR/*.txt

echo "✅ Secrets created successfully!"
echo ""
echo "📋 Generated secrets:"
echo "  - Database User: $DB_USER"
echo "  - Database Password: [generated]"
echo "  - PostgreSQL User: $POSTGRES_USER"
echo "  - PostgreSQL Password: [generated]"
echo "  - Keycloak Admin Password: [generated]"
echo ""
echo "🔒 Secret files created in: $SECRETS_DIR/"
echo "⚠️  Keep these files secure and never commit them to version control!"
echo ""
echo "🚀 To use secrets, run:"
echo "   docker-compose -f docker-compose.secrets.yml up -d" 