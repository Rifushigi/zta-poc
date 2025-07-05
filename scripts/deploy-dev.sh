#!/bin/bash
# scripts/deploy-dev.sh

# Source common functions
source "$(dirname "$0")/lib/common.sh"

# Show final status
show_final_status() {
    echo ""
    print_success "Zero Trust development deployment complete!"
    echo "============================================================"
    echo ""
    echo "Access URLs:"
    echo "=============="
    echo "Keycloak Admin: http://localhost:8080 (admin/admin)"
    echo "Express Gateway: http://localhost:8000"
    echo "Backend Service: http://localhost:3000"
    echo "OPA Policy Engine: http://localhost:8181"
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
    echo "Development Features:"
    echo "======================="
    echo "• Hot reloading enabled"
    echo "• Source code mounted for live editing"
    echo "• Development server on port 3000"
    echo ""
    echo "Test the deployment:"
    echo "======================"
    echo "./scripts/test-deployment.sh"
    echo ""
    echo "Monitor the system:"
    echo "====================="
    echo "Grafana Dashboards: http://localhost:3001"
    echo ""
    echo "Development Commands:"
    echo "======================="
    echo "Stop development: docker-compose -f docker-compose.yml down"
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
    
    # Deploy phase
    deploy_core_services
    setup_keycloak
    
    # Test phase
    export DEV_MODE=1
    test_deployment
    
    # Show results
    show_final_status
}

# Run main function
main 