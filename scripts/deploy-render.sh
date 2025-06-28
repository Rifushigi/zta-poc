#!/bin/bash

# 🚀 Render Deployment Script for Zero Trust
# This script prepares your project for Render deployment

set -e

echo "🚀 Preparing Zero Trust for Render deployment..."

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

# Check if required files exist
check_files() {
    print_status "Checking required files..."
    
    local required_files=(
        "docker-compose.render.yml"
        "Dockerfile.render"
        "nginx.render.conf"
        "services/frontend-app/Dockerfile"
        "services/backend-service/Dockerfile"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "✓ $file exists"
        else
            print_error "✗ $file missing"
            exit 1
        fi
    done
}

# Generate environment variables template
generate_env_template() {
    print_status "Generating environment variables template..."
    
    cat > .env.render.template << 'EOF'
# 🚀 Render Environment Variables Template
# Copy this to your Render service environment variables

# Database (use Render's managed PostgreSQL)
DATABASE_URL=postgresql://username:password@host:port/database

# Keycloak Configuration
KEYCLOAK_URL=https://your-app-name.onrender.com/auth
KEYCLOAK_REALM=zerotrust
KEYCLOAK_CLIENT_ID=frontend-app
KEYCLOAK_CLIENT_SECRET=your-client-secret-here
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=secure-password-here
KEYCLOAK_HOSTNAME=your-app-name.onrender.com

# Backend Configuration
BACKEND_URL=https://your-app-name.onrender.com/backend
JWT_SECRET=your-super-secret-jwt-key-here

# Monitoring URLs
PROMETHEUS_URL=https://your-app-name.onrender.com/monitoring/prometheus
GRAFANA_URL=https://your-app-name.onrender.com/monitoring/grafana

# Optional: Local PostgreSQL (if not using managed service)
POSTGRES_USER=backend
POSTGRES_PASSWORD=backendpass
POSTGRES_DB=zerotrust
EOF

    print_success "✓ Environment template created: .env.render.template"
}

# Create deployment checklist
create_checklist() {
    print_status "Creating deployment checklist..."
    
    cat > RENDER_CHECKLIST.md << 'EOF'
# ✅ Render Deployment Checklist

## Pre-Deployment
- [ ] Code pushed to GitHub repository
- [ ] All required files present (docker-compose.render.yml, Dockerfile.render, nginx.render.conf)
- [ ] Environment variables template reviewed (.env.render.template)

## Render Setup
- [ ] Render account created
- [ ] GitHub repository connected to Render
- [ ] Web Service created with Docker environment
- [ ] Environment variables configured in Render dashboard
- [ ] PostgreSQL service created (if using managed database)

## Configuration
- [ ] DATABASE_URL set correctly
- [ ] KEYCLOAK_URL points to your Render service
- [ ] KEYCLOAK_HOSTNAME matches your service URL
- [ ] All secrets and passwords configured
- [ ] JWT_SECRET set to secure value

## Deployment
- [ ] Build command: `docker-compose -f docker-compose.render.yml build`
- [ ] Start command: `docker-compose -f docker-compose.render.yml up`
- [ ] Service deployed successfully
- [ ] Health check passes: `https://your-app-name.onrender.com/health`

## Post-Deployment
- [ ] Keycloak admin console accessible
- [ ] Realm 'zerotrust' created in Keycloak
- [ ] Client 'frontend-app' created with correct settings
- [ ] Frontend application loads correctly
- [ ] Backend API endpoints working
- [ ] Monitoring dashboards accessible

## Testing
- [ ] User registration/login works
- [ ] Role-based access control functioning
- [ ] API gateway policies enforced
- [ ] Monitoring data being collected
- [ ] Alerts configured (if needed)

## Security
- [ ] SSL/TLS certificates working
- [ ] Security headers present
- [ ] Rate limiting configured
- [ ] Authentication flows working
- [ ] Authorization policies enforced
EOF

    print_success "✓ Deployment checklist created: RENDER_CHECKLIST.md"
}

# Show deployment instructions
show_instructions() {
    print_status "Displaying deployment instructions..."
    
    echo ""
    echo "🎯 RENDER DEPLOYMENT INSTRUCTIONS"
    echo "=================================="
    echo ""
    echo "1. 📁 PREPARE YOUR REPOSITORY"
    echo "   - Ensure all files are committed and pushed to GitHub"
    echo "   - Verify docker-compose.render.yml, Dockerfile.render, and nginx.render.conf exist"
    echo ""
    echo "2. 🌐 CREATE RENDER SERVICE"
    echo "   - Go to: https://dashboard.render.com"
    echo "   - Click 'New +' → 'Web Service'"
    echo "   - Connect your GitHub repository"
    echo "   - Configure:"
    echo "     • Name: zero-trust"
    echo "     • Environment: Docker"
    echo "     • Build Command: docker-compose -f docker-compose.render.yml build"
    echo "     • Start Command: docker-compose -f docker-compose.render.yml up"
    echo ""
    echo "3. 🔧 SET ENVIRONMENT VARIABLES"
    echo "   - Copy variables from .env.render.template"
    echo "   - Update URLs to match your service name"
    echo "   - Set secure passwords and secrets"
    echo ""
    echo "4. 🗄️ SETUP DATABASE"
    echo "   - Create PostgreSQL service in Render (recommended)"
    echo "   - Or use local PostgreSQL container"
    echo "   - Update DATABASE_URL in environment variables"
    echo ""
    echo "5. 🚀 DEPLOY"
    echo "   - Click 'Create Web Service'"
    echo "   - Wait for build to complete (5-10 minutes)"
    echo "   - Check logs for any errors"
    echo ""
    echo "6. 🔐 CONFIGURE KEYCLOAK"
    echo "   - Access: https://your-app-name.onrender.com/auth"
    echo "   - Login with admin credentials"
    echo "   - Create 'zerotrust' realm"
    echo "   - Create 'frontend-app' client"
    echo "   - Update KEYCLOAK_CLIENT_SECRET in Render"
    echo ""
    echo "7. ✅ TEST"
    echo "   - Main app: https://your-app-name.onrender.com"
    echo "   - Health check: https://your-app-name.onrender.com/health"
    echo "   - Backend: https://your-app-name.onrender.com/backend"
    echo "   - Monitoring: https://your-app-name.onrender.com/monitoring/grafana"
    echo ""
}

# Main execution
main() {
    echo "🚀 Zero Trust - Render Deployment Preparation"
    echo "============================================="
    echo ""
    
    # Check files
    check_files
    
    # Generate templates
    generate_env_template
    create_checklist
    
    # Show instructions
    show_instructions
    
    echo ""
    print_success "✅ Render deployment preparation complete!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Review .env.render.template and RENDER_CHECKLIST.md"
    echo "2. Push your code to GitHub"
    echo "3. Follow the deployment instructions above"
    echo "4. Configure environment variables in Render"
    echo "5. Deploy and test your application"
    echo ""
}

# Run main function
main 