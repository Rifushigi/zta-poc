#!/bin/bash
# scripts/deploy.sh

# Source common functions
source "$(dirname "$0")/lib/common.sh"

# Deploy frontend
deploy_frontend() {
    print_status "Deploying frontend application..."
    ./setup-frontend.sh prod
}

# Show final status
show_final_status() {
    echo ""
    print_success "Zero Trust deployment complete!"
    echo ""
    echo "🌐 Access URLs:"
    echo "=============="
    echo "Frontend (HTTP): http://localhost:8082"
    echo "Frontend (HTTPS): https://localhost:8081"
    echo "Keycloak Admin: http://localhost:8080 (admin/admin)"
    echo "API Gateway: http://localhost:8000"
    echo "Backend Service: http://localhost:4000"
    echo "OPA Policy Engine: https://localhost:8181"
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
    echo "./scripts/test-deployment.sh"
    echo ""
    echo "📊 Monitor the system:"
    echo "====================="
    echo "Grafana Dashboards: http://localhost:3001"
    echo "Security Overview: http://localhost:8082/security"
    echo ""
}

# Main execution
main() {
    echo "🚀 Zero Trust Deployment"
    echo "======================="
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