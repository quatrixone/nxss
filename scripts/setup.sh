#!/bin/bash

# NXSS Setup Script - Sets up the development environment
# Usage: ./scripts/setup.sh

set -e

echo "🔧 NXSS Development Setup"
echo "========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we're in the right directory
if [ ! -d "server" ] || [ ! -d "clients" ]; then
    print_error "Please run this script from the NXSS project root directory"
    exit 1
fi

# Check for required tools
print_status "Checking required tools..."

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed. Please install Node.js first."
    exit 1
else
    NODE_VERSION=$(node --version)
    print_success "Node.js found: $NODE_VERSION"
fi

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is required but not installed. Please install npm first."
    exit 1
else
    NPM_VERSION=$(npm --version)
    print_success "npm found: $NPM_VERSION"
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_warning "Flutter not found. Mobile/desktop apps won't be buildable."
    print_status "To install Flutter: https://docs.flutter.dev/get-started/install"
else
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter found: $FLUTTER_VERSION"
    
    # Enable desktop platforms
    print_status "Enabling Flutter desktop platforms..."
    flutter config --enable-linux-desktop --enable-windows-desktop --enable-macos-desktop
fi

# Install server dependencies
print_status "Installing server dependencies..."
cd server
if [ ! -f "package.json" ]; then
    print_error "Server package.json not found!"
    exit 1
fi
npm install
cd ..

# Install CLI dependencies
print_status "Installing CLI dependencies..."
cd clients/cli
if [ ! -f "package.json" ]; then
    print_error "CLI package.json not found!"
    exit 1
fi
npm install
cd ../..

# Install Flutter dependencies
if command -v flutter &> /dev/null; then
    print_status "Installing Flutter dependencies..."
    cd clients/flutter
    flutter pub get
    
    # Create platform folders if they don't exist
    print_status "Setting up Flutter platform folders..."
    flutter create --platforms=windows,linux,macos . 2>/dev/null || true
    cd ../..
fi

# Create .env file if it doesn't exist
print_status "Setting up server configuration..."
if [ ! -f "server/.env" ]; then
    if [ -f "server/.env.example" ]; then
        cp server/.env.example server/.env
        print_success "Created server/.env from example"
    else
        print_warning "No .env.example found. You may need to create server/.env manually"
    fi
else
    print_success "Server .env already exists"
fi

# Create builds directory
print_status "Creating build directories..."
mkdir -p builds/{windows,linux,macos,android,ios}

print_success "Setup completed successfully!"
echo ""
echo "🎉 Next steps:"
echo "1. Configure your server: edit server/.env"
echo "2. Start the server: cd server && npm start"
echo "3. Build clients: ./scripts/build-all.sh"
echo "4. Test CLI: cd clients/cli && npm install -g ."
echo ""
echo "📚 Documentation:"
echo "- Server setup: server/README.md"
echo "- CLI usage: clients/cli/README.md"
echo "- Mobile app: mobile/nxss_mobile/README.md"
echo "- Builds: builds/README.md"
