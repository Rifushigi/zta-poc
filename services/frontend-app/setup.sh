#!/bin/bash

echo "🚀 Setting up Zero Trust Frontend Application..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Create environment file
echo "🔧 Creating environment configuration..."
cat > .env << EOF
REACT_APP_API_URL=http://localhost:3000
REACT_APP_KEYCLOAK_URL=http://localhost:8080
EOF

echo "✅ Environment file created"

echo ""
echo "🎉 Frontend setup complete!"
echo ""
echo "To start development:"
echo "  npm run dev"
echo ""
echo "To build for production:"
echo "  npm run build:prod"
echo ""
echo "The frontend will be available at:"
echo "  Development: http://localhost:3000"
echo "  Production:  https://localhost:8080" 