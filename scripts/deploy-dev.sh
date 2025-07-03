#!/bin/bash
# scripts/deploy-dev.sh

# Source common functions
source "$(dirname "$0")/lib/common.sh"

# Deploy frontend in development mode
deploy_frontend_dev() {
    print_status "Deploying frontend in development mode..."
    docker-compose -f ../docker-compose.yml -f ../docker-compose.frontend-dev.yml up -d frontend-dev
    
    # Wait for frontend to be ready
    print_status "Waiting for frontend to be ready..."
    sleep 10
}

# Show final status
show_final_status() {
    echo ""
    print_success "Zero Trust development deployment complete!"
    echo ""
    echo "🌐 Access URLs:"
    echo "=============="
    echo "Frontend (Dev): http://localhost:3000"
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
    echo "🛠️ Development Features:"
    echo "======================="
    echo "• Hot reloading enabled"
    echo "• Source code mounted for live editing"
    echo "• Development server on port 3000"
    echo "• No SSL required for frontend"
    echo ""
    echo "🧪 Test the deployment:"
    echo "======================"
    echo "./scripts/test-deployment.sh"
    echo ""
    echo "📊 Monitor the system:"
    echo "====================="
    echo "Grafana Dashboards: http://localhost:3001"
    echo "Security Overview: http://localhost:3000/security"
    echo ""
    echo "🔄 Development Commands:"
    echo "======================="
    echo "View frontend logs: docker-compose -f docker-compose.yml -f docker-compose.frontend-dev.yml logs -f frontend-dev"
    echo "Restart frontend: docker-compose -f docker-compose.yml -f docker-compose.frontend-dev.yml restart frontend-dev"
    echo "Stop development: docker-compose -f docker-compose.yml -f docker-compose.frontend-dev.yml down"
    echo ""
}

# Main execution
main() {
    echo "Zero Trust Development Deployment"
    echo "==================================="
    echo ""
    
    # Pre-flight checks
    check_docker
    
    # Setup phase
    setup_networks
    setup_certificates
    
    # Deploy phase
    deploy_core_services
    setup_keycloak
    deploy_frontend_dev
    
    # Test phase
    export DEV_MODE=1
    test_deployment
    
    # Show results
    show_final_status
}

# Run main function
main 