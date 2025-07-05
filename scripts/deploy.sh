#!/bin/bash
# scripts/deploy.sh

# Source common functions
source "$(dirname "$0")/lib/common.sh"

# Show final status
show_final_status() {
    echo ""
    print_success "Zero Trust deployment complete!"
    echo ""
    echo "Access URLs:"
    echo "=============="
    echo "Keycloak Admin: http://localhost:8080 (admin/admin)"
    echo "Express Gateway: http://localhost:8000"
    echo "Backend Service: http://localhost:4000"
    echo "OPA Policy Engine: https://localhost:8181"
    echo "Grafana: http://localhost:3001 (admin/admin)"
    echo "Prometheus: http://localhost:9090"
    echo "Alertmanager: http://localhost:9093"
    echo "Kibana: http://localhost:5601"
    echo ""
    echo "Demo Credentials:"
    echo "==================="
    echo "User: user / password123"
    echo "Admin: admin / admin123"
    echo ""
    echo "Test the deployment:"
    echo "======================"
    echo "./scripts/test-deployment.sh"
    echo ""
    echo "Monitor the system:"
    echo "====================="
    echo "Grafana Dashboards: http://localhost:3001"
    echo ""
}

# Main execution
main() {
    echo "Zero Trust Deployment"
    echo "======================="
    echo ""
    
    # Pre-flight checks
    check_docker
    
    # Setup phase
    setup_secrets
    setup_networks
    
    # Deploy phase
    deploy_core_services
    setup_keycloak
    
    # Test phase
    test_deployment
    
    # Show results
    show_final_status
}

# Run main function
main 