#!/bin/bash
# scripts/switch-frontend-mode.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔄 Zero Trust Frontend Mode Switcher"
echo "===================================="
echo ""

# Check if frontend is running
if ! docker ps | grep -q "frontend-app"; then
    echo -e "${RED}❌ Frontend is not running. Please start it first:${NC}"
    echo "   ./scripts/deploy.sh"
    exit 1
fi

echo "Current frontend URLs:"
echo -e "${BLUE}HTTP:${NC}  http://localhost:8082"
echo -e "${BLUE}HTTPS:${NC} https://localhost:8081"
echo ""

echo "Choose your preferred mode:"
echo "1) HTTP (Recommended for development - no browser warnings)"
echo "2) HTTPS (Production-like, but with browser warnings for self-signed certs)"
echo "3) Both (Access via either URL)"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}✅ Using HTTP mode${NC}"
        echo ""
        echo "🌐 Access your frontend at:"
        echo -e "${BLUE}http://localhost:8082${NC}"
        echo ""
        echo "✅ Benefits:"
        echo "   • No browser security warnings"
        echo "   • Faster development workflow"
        echo "   • Perfect for POC and testing"
        echo ""
        echo "⚠️  Note: This is suitable for development and POC environments."
        echo "   For production, use HTTPS with proper certificates."
        ;;
    2)
        echo ""
        echo -e "${YELLOW}⚠️  Using HTTPS mode${NC}"
        echo ""
        echo "🌐 Access your frontend at:"
        echo -e "${BLUE}https://localhost:8081${NC}"
        echo ""
        echo "⚠️  Browser will show security warning due to self-signed certificate."
        echo "   To proceed:"
        echo "   1. Click 'Advanced'"
        echo "   2. Click 'Proceed to localhost (unsafe)'"
        echo ""
        echo "✅ Benefits:"
        echo "   • Production-like environment"
        echo "   • Tests HTTPS functionality"
        echo "   • More secure for sensitive data"
        ;;
    3)
        echo ""
        echo -e "${GREEN}✅ Using both modes${NC}"
        echo ""
        echo "🌐 Access your frontend at:"
        echo -e "${BLUE}HTTP:${NC}  http://localhost:8082 (no warnings)"
        echo -e "${BLUE}HTTPS:${NC} https://localhost:8081 (with warnings)"
        echo ""
        echo "✅ Benefits:"
        echo "   • Flexibility to use either mode"
        echo "   • HTTP for development, HTTPS for testing"
        echo "   • Easy switching between modes"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice. Please run the script again.${NC}"
        exit 1
        ;;
esac

echo ""
echo "🔧 To restart the frontend with new settings:"
echo "   docker-compose restart frontend-app"
echo ""
echo "📚 For more information, see:"
echo "   services/frontend-app/DEPLOYMENT.md" 