#!/bin/bash

# Zero Trust Frontend Setup Script
set -e

echo "🚀 Zero Trust Frontend Setup & Deployment"
echo "=========================================="

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

# Check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Check if networks exist
check_networks() {
    print_status "Checking Docker networks..."
    
    if ! docker network ls | grep -q "on-prem-net"; then
        print_warning "on-prem-net network not found. Creating..."
        docker network create on-prem-net
        print_success "Created on-prem-net network"
    else
        print_success "on-prem-net network exists"
    fi
    
    if ! docker network ls | grep -q "cloud-net"; then
        print_warning "cloud-net network not found. Creating..."
        docker network create cloud-net
        print_success "Created cloud-net network"
    else
        print_success "cloud-net network exists"
    fi
}

# Check if certificates exist
check_certificates() {
    print_status "Checking SSL certificates..."
    
    if [ ! -f "certs/server.crt" ] || [ ! -f "certs/server.key" ]; then
        print_warning "SSL certificates not found. Running certificate generation..."
        if [ -f "scripts/generate-certs.sh" ]; then
            ./scripts/generate-certs.sh
            print_success "Generated SSL certificates"
        else
            print_error "Certificate generation script not found. Please run setup.sh first."
            exit 1
        fi
    else
        print_success "SSL certificates exist"
    fi
}

# Build frontend image
build_frontend() {
    print_status "Building frontend Docker image..."
    
    cd services/frontend-app
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in services/frontend-app"
        exit 1
    fi
    
    # Build the image
    docker build -t zero-trust-frontend:latest .
    
    if [ $? -eq 0 ]; then
        print_success "Frontend image built successfully"
    else
        print_error "Failed to build frontend image"
        exit 1
    fi
    
    cd ../..
}

# Deploy with Docker Compose
deploy_frontend() {
    local mode=$1
    
    print_status "Deploying frontend in $mode mode..."
    
    if [ "$mode" = "dev" ]; then
        # Development mode
        docker-compose -f docker-compose.yml -f docker-compose.frontend-dev.yml up -d frontend-dev
        
        print_success "Frontend deployed in development mode"
        print_status "Access the frontend at: http://localhost:3000"
        print_status "Hot reloading is enabled for development"
        
    else
        # Production mode
        docker-compose -f docker-compose.yml up -d frontend-app
        
        print_success "Frontend deployed in production mode"
        print_status "Access the frontend at: https://localhost:8080"
        print_status "SSL/TLS is enabled for production"
    fi
}

# Show deployment status
show_status() {
    print_status "Checking deployment status..."
    
    echo ""
    echo "📊 Deployment Status:"
    echo "===================="
    
    # Check if containers are running
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "frontend"; then
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep "frontend"
    else
        print_warning "No frontend containers found running"
    fi
    
    echo ""
    echo "🌐 Access URLs:"
    echo "=============="
    echo "Frontend (Production): https://localhost:8080"
    echo "Frontend (Development): http://localhost:3000"
    echo "Keycloak Admin: http://localhost:8080"
    echo "Grafana: http://localhost:3001"
    echo "Prometheus: http://localhost:9090"
    echo "Alertmanager: http://localhost:9093"
    echo "Kibana: http://localhost:5601"
    
    echo ""
    echo "🔧 Management Commands:"
    echo "======================"
    echo "View logs: docker-compose -f docker-compose.yml logs frontend-app"
    echo "Stop: docker-compose -f docker-compose.yml stop frontend-app"
    echo "Restart: docker-compose -f docker-compose.yml restart frontend-app"
    echo "Remove: docker-compose -f docker-compose.yml down"
}

# Main execution
main() {
    local mode=${1:-prod}
    
    echo ""
    print_status "Starting frontend setup and deployment..."
    
    # Pre-flight checks
    check_docker
    check_docker_compose
    check_networks
    check_certificates
    
    # Build and deploy
    build_frontend
    deploy_frontend $mode
    
    # Show status
    show_status
    
    echo ""
    print_success "Frontend setup and deployment completed successfully!"
    echo ""
    print_status "Demo Credentials:"
    echo "  User: user / password123"
    echo "  Admin: admin / admin123"
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    "dev"|"development")
        main "dev"
        ;;
    "prod"|"production"|"")
        main "prod"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [dev|prod]"
        echo ""
        echo "Options:"
        echo "  dev, development    Deploy in development mode with hot reloading"
        echo "  prod, production    Deploy in production mode (default)"
        echo "  help, -h, --help    Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                 # Deploy in production mode"
        echo "  $0 dev            # Deploy in development mode"
        echo "  $0 production     # Deploy in production mode"
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 