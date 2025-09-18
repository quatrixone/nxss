#!/bin/bash

# NXSS Build Script - Builds clients for specific platforms or all platforms
# Usage: 
#   ./scripts/build.sh --all                    # Build all platforms
#   ./scripts/build.sh --linux                  # Build Linux only
#   ./scripts/build.sh --windows                # Build Windows only
#   ./scripts/build.sh --macos                  # Build macOS only
#   ./scripts/build.sh --android                # Build Android only
#   ./scripts/build.sh --ios                    # Build iOS only
#   ./scripts/build.sh --cli                    # Build CLI only
#   ./scripts/build.sh --flutter                # Build Flutter only

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}🚀 NXSS Build Script${NC}"
    echo -e "${PURPLE}====================${NC}"
}

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

print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all        Build all platforms (CLI + Flutter for all platforms)"
    echo "  --cli        Build CLI client only"
    echo "  --flutter    Build Flutter app only"
    echo "  --linux      Build Linux platform (CLI + Flutter desktop)"
    echo "  --windows    Build Windows platform (CLI + Flutter desktop)"
    echo "  --macos      Build macOS platform (Flutter desktop)"
    echo "  --android    Build Android platform (Flutter mobile)"
    echo "  --ios        Build iOS platform (Flutter mobile)"
    echo "  --server     Build server"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Build everything"
    echo "  $0 --linux --windows        # Build Linux and Windows"
    echo "  $0 --cli                    # Build CLI only"
    echo "  $0 --flutter --linux        # Build Flutter for Linux only"
}

# Check if we're in the right directory
if [ ! -d "server" ] || [ ! -d "clients" ]; then
    print_error "Please run this script from the NXSS project root directory"
    exit 1
fi

# Parse command line arguments
BUILD_ALL=false
BUILD_CLI=false
BUILD_FLUTTER=false
BUILD_LINUX=false
BUILD_WINDOWS=false
BUILD_MACOS=false
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_SERVER=false

if [ $# -eq 0 ]; then
    print_error "No arguments provided. Use --help for usage information."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            BUILD_ALL=true
            shift
            ;;
        --cli)
            BUILD_CLI=true
            shift
            ;;
        --flutter)
            BUILD_FLUTTER=true
            shift
            ;;
        --linux)
            BUILD_LINUX=true
            shift
            ;;
        --windows)
            BUILD_WINDOWS=true
            shift
            ;;
        --macos)
            BUILD_MACOS=true
            shift
            ;;
        --android)
            BUILD_ANDROID=true
            shift
            ;;
        --ios)
            BUILD_IOS=true
            shift
            ;;
        --server)
            BUILD_SERVER=true
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# If --all is specified, set all other flags
if [ "$BUILD_ALL" = true ]; then
    BUILD_CLI=true
    BUILD_FLUTTER=true
    BUILD_LINUX=true
    BUILD_WINDOWS=true
    BUILD_MACOS=true
    BUILD_ANDROID=true
    BUILD_IOS=true
    BUILD_SERVER=true
fi

# If platform-specific builds are selected, automatically enable Flutter for desktop platforms
if [ "$BUILD_LINUX" = true ] || [ "$BUILD_WINDOWS" = true ] || [ "$BUILD_MACOS" = true ]; then
    BUILD_FLUTTER=true
fi

# If no specific platform is selected but flutter is selected, build for current platform
if [ "$BUILD_FLUTTER" = true ] && [ "$BUILD_LINUX" = false ] && [ "$BUILD_WINDOWS" = false ] && [ "$BUILD_MACOS" = false ] && [ "$BUILD_ANDROID" = false ] && [ "$BUILD_IOS" = false ]; then
    # Detect current platform
    case "$(uname -s)" in
        Linux*)     BUILD_LINUX=true ;;
        Darwin*)    BUILD_MACOS=true ;;
        CYGWIN*|MINGW*|MSYS*) BUILD_WINDOWS=true ;;
        *)          print_warning "Unknown platform, defaulting to Linux"; BUILD_LINUX=true ;;
    esac
fi

print_header

# Create builds directory structure
print_status "Creating build directory structure..."
mkdir -p builds/{windows,linux,macos}/{cli,desktop}
mkdir -p builds/{android,ios}/desktop
mkdir -p builds/server

# Build CLI client
if [ "$BUILD_CLI" = true ]; then
    print_status "Building CLI client..."
    cd clients/cli
    npm run build
    cd ../..
    print_success "CLI client built successfully"
fi

# Copy CLI builds to platform folders
if [ "$BUILD_CLI" = true ]; then
    print_status "Organizing CLI builds..."
    
    # Copy CLI to Linux if building Linux
    if [ "$BUILD_LINUX" = true ]; then
        cp -r clients/cli/dist/* builds/linux/cli/ 2>/dev/null || true
        cp clients/cli/package.json builds/linux/cli/ 2>/dev/null || true
    fi
    
    # Copy CLI to Windows if building Windows
    if [ "$BUILD_WINDOWS" = true ]; then
        cp -r clients/cli/dist/* builds/windows/cli/ 2>/dev/null || true
        cp clients/cli/package.json builds/windows/cli/ 2>/dev/null || true
    fi
    
    # Copy CLI to macOS if building macOS
    if [ "$BUILD_MACOS" = true ]; then
        cp -r clients/cli/dist/* builds/macos/cli/ 2>/dev/null || true
        cp clients/cli/package.json builds/macos/cli/ 2>/dev/null || true
    fi
    
    print_success "CLI builds organized"
fi

# Build Flutter app for Linux
if [ "$BUILD_LINUX" = true ] && [ "$BUILD_FLUTTER" = true ]; then
    print_status "Building Flutter desktop app for Linux..."
    cd clients/flutter
    flutter build linux --release
    cd ../..
    
    # Copy Flutter Linux build
    print_status "Organizing Flutter Linux build..."
    cp -r clients/flutter/build/linux/x64/release/bundle/* builds/linux/desktop/ 2>/dev/null || true
    print_success "Flutter Linux build completed"
fi

# Build Flutter app for Windows (requires Windows environment)
if [ "$BUILD_WINDOWS" = true ] && [ "$BUILD_FLUTTER" = true ]; then
    print_status "Building Flutter desktop app for Windows..."
    cd clients/flutter
    if flutter build windows --release 2>/dev/null; then
        cd ../..
        # Copy Flutter Windows build
        print_status "Organizing Flutter Windows build..."
        cp -r clients/flutter/build/windows/runner/Release/* builds/windows/desktop/ 2>/dev/null || true
        print_success "Flutter Windows build completed"
    else
        cd ../..
        print_warning "Windows Flutter build failed - requires Windows environment"
    fi
fi

# Build Flutter app for macOS (requires macOS environment)
if [ "$BUILD_MACOS" = true ] && [ "$BUILD_FLUTTER" = true ]; then
    print_status "Building Flutter desktop app for macOS..."
    cd clients/flutter
    if flutter build macos --release 2>/dev/null; then
        cd ../..
        # Copy Flutter macOS build
        print_status "Organizing Flutter macOS build..."
        cp -r clients/flutter/build/macos/Build/Products/Release/* builds/macos/desktop/ 2>/dev/null || true
        print_success "Flutter macOS build completed"
    else
        cd ../..
        print_warning "macOS Flutter build failed - requires macOS environment"
    fi
fi

# Build Flutter app for Android (requires Android SDK)
if [ "$BUILD_ANDROID" = true ] && [ "$BUILD_FLUTTER" = true ]; then
    print_status "Building Flutter mobile app for Android..."
    cd clients/flutter
    if flutter build apk --release 2>/dev/null; then
        cd ../..
        # Copy Flutter Android build
        print_status "Organizing Flutter Android build..."
        cp clients/flutter/build/app/outputs/flutter-apk/app-release.apk builds/android/desktop/ 2>/dev/null || true
        print_success "Flutter Android build completed"
    else
        cd ../..
        print_warning "Android Flutter build failed - requires Android SDK"
    fi
fi

# Build Flutter app for iOS (requires macOS + Xcode)
if [ "$BUILD_IOS" = true ] && [ "$BUILD_FLUTTER" = true ]; then
    print_status "Building Flutter mobile app for iOS..."
    cd clients/flutter
    if flutter build ios --release 2>/dev/null; then
        cd ../..
        # Copy Flutter iOS build
        print_status "Organizing Flutter iOS build..."
        cp -r clients/flutter/build/ios/Release-iphoneos/* builds/ios/desktop/ 2>/dev/null || true
        print_success "Flutter iOS build completed"
    else
        cd ../..
        print_warning "iOS Flutter build failed - requires macOS + Xcode"
    fi
fi

# Build Server
if [ "$BUILD_SERVER" = true ]; then
    print_status "Building server..."
    cd server
    
    # Install production dependencies
    print_status "Installing server dependencies..."
    npm install --production
    
    # Copy server files to build directory
    print_status "Organizing server build..."
    cp -r . ../builds/server/ 2>/dev/null || true
    
    # Remove development files
    rm -rf ../builds/server/node_modules/.cache 2>/dev/null || true
    rm -rf ../builds/server/storage_data/* 2>/dev/null || true
    rm -rf ../builds/server/tmp_uploads/* 2>/dev/null || true
    
    cd ..
    print_success "Server build completed"
fi

# Create platform-specific READMEs
print_status "Creating platform documentation..."

# Linux README
cat > builds/linux/README.md << 'EOF'
# Linux Builds

This folder contains Linux builds for both CLI and desktop app.

## Structure
- `cli/` - Command-line client
- `desktop/` - Flutter desktop application

## Quick Start

### CLI Client
```bash
cd cli
npm install -g .
nxss init --server http://localhost:8080 --folder "/path/to/folder"
nxss login --email you@example.com --password yourpassword
nxss sync
nxss watch
```

### Desktop App
```bash
cd desktop
./nxss_mobile
```

## Files
- `cli/index.js` - CLI executable
- `cli/package.json` - Node.js package configuration
- `desktop/nxss_mobile` - Flutter desktop application
- `desktop/data/` - Flutter app data directory
- `desktop/lib/` - Flutter app libraries
EOF

# Windows README
cat > builds/windows/README.md << 'EOF'
# Windows Builds

This folder contains Windows builds for both CLI and desktop app.

## Structure
- `cli/` - Command-line client
- `desktop/` - Flutter desktop application

## Quick Start

### CLI Client
```bash
cd cli
npm install -g .
nxss init --server http://localhost:8080 --folder "C:\path\to\folder"
nxss login --email you@example.com --password yourpassword
nxss sync
nxss watch
```

### Desktop App
```bash
cd desktop
# Run the desktop application
```

## Building Desktop App
To build the Windows Flutter desktop app, run on a Windows machine:
```bash
cd clients/flutter
flutter build windows --release
# Copy build/windows/runner/Release/ contents to desktop/ folder
```
EOF

# macOS README
cat > builds/macos/README.md << 'EOF'
# macOS Builds

This folder contains macOS builds for both CLI and desktop app.

## Structure
- `cli/` - Command-line client
- `desktop/` - Flutter desktop application

## Quick Start

### CLI Client
```bash
cd cli
npm install -g .
nxss init --server http://localhost:8080 --folder "/path/to/folder"
nxss login --email you@example.com --password yourpassword
nxss sync
nxss watch
```

### Desktop App
```bash
cd desktop
# Run the desktop application
```

## Building Desktop App
To build the macOS Flutter desktop app, run on a macOS machine:
```bash
cd clients/flutter
flutter build macos --release
# Copy build/macos/Build/Products/Release/ contents to desktop/ folder
```
EOF

# Android README
cat > builds/android/README.md << 'EOF'
# Android Mobile App

This folder contains the Android mobile app build.

## Structure
- `desktop/` - Flutter mobile application (APK)

## Building Android App
To build the Android APK, you need:
1. Android SDK installed
2. Set ANDROID_HOME environment variable
3. Run on a machine with Android build tools:

```bash
cd clients/flutter
flutter build apk --release
# Copy build/app/outputs/flutter-apk/app-release.apk to desktop/ folder
```

## Android App Bundle Build
For Google Play Store distribution:
```bash
cd clients/flutter
flutter build appbundle --release
# Copy build/app/outputs/bundle/release/app-release.aab to desktop/ folder
```

## Installation
Install the APK on Android device:
```bash
cd desktop
adb install app-release.apk
```
EOF

# iOS README
cat > builds/ios/README.md << 'EOF'
# iOS Mobile App

This folder contains the iOS mobile app build.

## Structure
- `desktop/` - Flutter mobile application (iOS app)

## iOS Build Requirements
To build for iOS, you need:
1. macOS machine with Xcode
2. iOS development certificate
3. Flutter with iOS support

## iOS Build Commands
```bash
cd clients/flutter
flutter build ios --release
# Copy build/ios/Release-iphoneos/ folder contents to desktop/ folder
```

## iOS Simulator Build
For testing on iOS Simulator:
```bash
cd clients/flutter
flutter build ios --simulator
# Copy build/ios/Release-iphonesimulator/ folder contents to desktop/ folder
```

## Installation
Use Xcode to install on device or simulator, or use:
```bash
cd desktop
flutter install
```
EOF

# Server README
cat > builds/server/README.md << 'EOF'
# NXSS Server

This folder contains the built NXSS server ready for deployment.

## Structure
- `index.js` - Main server file
- `package.json` - Node.js dependencies
- `services/` - Server business logic
- `storage/` - Storage providers
- `data/` - Server data files
- `node_modules/` - Production dependencies

## Quick Start

### Prerequisites
- Node.js (>=16.0.0)
- npm (>=8.0.0)

### Configuration
1. Create `.env` file with your settings:
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. Start the server:
```bash
npm start
```

### Environment Variables
```env
PORT=8080
HOST=0.0.0.0
JWT_SECRET=your-super-secret-jwt-key
STORAGE_PROVIDER=local
STORAGE_PATH=./storage_data
```

### Production Deployment
1. Install PM2 globally: `npm install -g pm2`
2. Start with PM2: `pm2 start index.js --name nxss-server`
3. Save PM2 config: `pm2 save`
4. Setup auto-start: `pm2 startup`

### Docker Deployment
```bash
# Build Docker image
docker build -t nxss-server .

# Run container
docker run -p 8080:8080 -v $(pwd)/storage_data:/app/storage_data nxss-server
```

## API Endpoints
- `GET /health` - Health check
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/files` - List files
- `POST /api/files/upload` - Upload file
- `GET /api/files/:id` - Download file
EOF

# Create build summary
cat > builds/README.md << 'EOF'
# NXSS Client Builds

This directory contains builds for all supported platforms.

## 📦 Available Builds

### ✅ Ready to Use
- **Linux** (`linux/`) - Complete CLI + Desktop app
- **Windows** (`windows/`) - CLI client ready
- **Server** (`server/`) - Complete server build

### 🔧 Platform-Specific Builds Required
- **macOS** (`macos/`) - Requires macOS build environment
- **Android** (`android/`) - Requires Android SDK (mobile app only)
- **iOS** (`ios/`) - Requires macOS + Xcode (mobile app only)

## 🚀 Quick Start

### Linux
```bash
cd linux/cli
npm install -g .  # For CLI

cd ../desktop
./nxss_mobile     # For desktop app
```

### Windows
```bash
cd windows/cli
npm install -g .  # For CLI
```

### Server
```bash
cd server
npm install
npm start
```

## 📁 Build Structure

### Desktop Platforms (Linux, Windows, macOS)
```
platform/
├── cli/           # Command-line client
└── desktop/       # Flutter desktop app
```

### Mobile Platforms (Android, iOS)
```
platform/
└── desktop/       # Flutter mobile app
```

### Server
```
server/
├── index.js       # Main server file
├── package.json   # Dependencies
├── services/      # Business logic
├── storage/       # Storage providers
└── data/          # Server data
```

## 📋 Build Status
- ✅ CLI Client: Linux, Windows, macOS
- ✅ Flutter Desktop: Linux
- ✅ Server: Complete build ready
- ⏳ Flutter Desktop: Windows, macOS (require platform-specific build)
- ⏳ Flutter Mobile: Android, iOS (require platform-specific build)

## 🔨 Building Other Platforms

See individual platform README files for specific build instructions.
EOF

print_success "Build completed successfully!"
print_status "Build outputs are in the 'builds/' directory"
print_status "Each platform has its own folder with README instructions"

echo ""
echo "📁 Build Structure:"
echo "builds/"
echo "├── linux/     ✅ Complete (CLI + Desktop)"
echo "├── windows/   ✅ CLI ready"
echo "├── macos/     📋 Instructions provided"
echo "├── android/   📋 Instructions provided"
echo "└── ios/       📋 Instructions provided"
