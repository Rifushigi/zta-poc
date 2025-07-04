#!/bin/bash
# scripts/lib/common.sh
# Common functions and utilities for deployment scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Setup networks
setup_networks() {
    print_status "Setting up networks..."
    ./setup-networks.sh
}

# Generate certificates
setup_certificates() {
    print_status "Setting up certificates..."
    if [ ! -d "../certs" ] || [ -z "$(ls -A ../certs 2>/dev/null)" ]; then
        ./generate-certs.sh
        print_success "Certificates generated"
    else
        print_success "Certificates already exist"
    fi
}

# Setup secrets if missing
setup_secrets() {
    if [ ! -f secrets/db_user.txt ]; then
        print_status "Setting up secrets..."
        ./setup-secrets.sh
    else
        print_success "Secrets already configured"
    fi
}

# Deploy core services
deploy_core_services() {
    print_status "Deploying core services..."
    docker compose up -d --build
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
}

# Setup Keycloak
setup_keycloak() {
    print_status "Setting up Keycloak realm and users..."
    ./setup-keycloak.sh
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    ./test-deployment.sh
} 
