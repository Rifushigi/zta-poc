#!/bin/bash
# scripts/deploy.sh

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

# Setup secrets if missing
setup_secrets() {
    if [ ! -f secrets/db_user.txt ]; then
        print_status "Setting up secrets..."
        ./setup-secrets.sh
    else
        print_success "Secrets already configured"
    fi
}

# Setup networks
setup_networks() {
    print_status "Setting up networks..."
    ./setup-networks.sh
}

# Generate certificates
setup_certificates() {
    print_status "Setting up certificates..."
    if [ ! -d "certs" ] || [ -z "$(ls -A certs 2>/dev/null)" ]; then
        ./generate-certs.sh
        print_success "Certificates generated"
    else
        print_success "Certificates already exist"
    fi
}

# Deploy core services
deploy_core_services() {
    print_status "Deploying core services..."
    docker-compose up -d --build
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
}

# Setup Keycloak
setup_keycloak() {
    print_status "Setting up Keycloak realm and users..."
    ./setup-keycloak.sh
}

# Deploy frontend
deploy_frontend() {
    print_status "Deploying frontend application..."
    ./setup-frontend.sh prod
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    ./test-deployment.sh
}

# Show final status
show_final_status() {
    echo ""
    print_success "Zero Trust PoC deployment complete!"
    echo ""
    echo "🌐 Access URLs:"
    echo "=============="
    echo "Frontend: https://localhost:8080"
    echo "Keycloak Admin: http://localhost:8080 (admin/admin)"
    echo "API Gateway: https://localhost:8443"
    echo "Backend Service: http://localhost:3000"
    echo "OPA Policy Engine: http://localhost:8181"
    echo "Grafana: http://localhost:3001 (admin/admin)"
    echo "Prometheus: http://localhost:9090"
    echo "Alertmanager: http://localhost:9093"
    echo "Kibana: http://localhost:5601"
    echo ""
    echo "🔑 Demo Credentials:"
    echo "==================="
    echo "User: user / password123"
    echo "Admin: admin / admin123"
    echo ""
    echo "🧪 Test the deployment:"
    echo "======================"
    echo "./test-deployment.sh"
    echo ""
    echo "📊 Monitor the system:"
    echo "====================="
    echo "Grafana Dashboards: http://localhost:3001"
    echo "Security Overview: https://localhost:8080/security"
    echo ""
}

# Main execution
main() {
    echo "🚀 Zero Trust PoC Deployment"
    echo "============================"
    echo ""
    
    # Pre-flight checks
    check_docker
    
    # Setup phase
    setup_secrets
    setup_networks
    setup_certificates
    
    # Deploy phase
    deploy_core_services
    setup_keycloak
    deploy_frontend
    
    # Test phase
    test_deployment
    
    # Show results
    show_final_status
}

# Run main function
main 