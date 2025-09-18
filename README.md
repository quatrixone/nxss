# NXSS: Cross-Platform File Sync System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?logo=node.js&logoColor=white)](https://nodejs.org)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://docker.com)

🔄 **A modern, self-hostable file synchronization system** that works seamlessly across all your devices. Sync your files between computers, phones, and tablets with full control over your data.

## ✨ Features

- 🖥️ **Cross-Platform Support** - Windows, Linux, macOS, Android, iOS
- 📱 **Native Mobile Apps** - Beautiful Flutter-based mobile and desktop apps
- 🖥️ **Desktop Applications** - Native desktop apps for all major platforms
- 🔧 **Command Line Interface** - Powerful CLI for automation and scripting
- ☁️ **Flexible Storage** - Local storage or Google Drive integration
- 🔒 **Privacy First** - Self-hosted with no data collection
- 🚀 **Easy Setup** - Docker support for quick deployment
- 🔄 **Real-time Sync** - Automatic file synchronization across devices
- 📁 **Folder Pairing** - Smart folder mapping with server folder selection
- ⚙️ **Configurable** - Customizable server settings and storage options

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CLI Client    │    │  Mobile/Desktop │    │  Web Interface  │
│  (Node.js)      │    │   (Flutter)     │    │   (Future)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  NXSS Server    │
                    │  (Node.js)      │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Storage Layer  │
                    │ (Local/GDrive)  │
                    └─────────────────┘
```

## 🚀 Quick Start

### Option 1: Docker (Recommended)

The easiest way to get started is with Docker:

```bash
# Clone the repository
git clone https://github.com/your-username/nxss.git
cd nxss/server

# Start with Docker Compose
docker compose up -d

# The server will be available at http://localhost:8080
```

### Option 2: Manual Setup

#### 1. Prerequisites

- **Node.js** 18+ and npm
- **Flutter SDK** (for mobile/desktop apps)
- **Git** for cloning the repository

#### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-username/nxss.git
cd nxss

# Install dependencies
npm install

# Setup development environment
npm run setup
```

#### 3. Start the Server

```bash
# Start the server
npm run start:server
# or
cd server && npm start
```

The server will be available at `http://localhost:8080`

#### 4. Run Mobile/Desktop Apps

```bash
# Navigate to Flutter app
cd clients/flutter

# Install Flutter dependencies
flutter pub get

# Run on your preferred platform
flutter run -d linux    # Linux desktop
flutter run -d windows  # Windows desktop
flutter run -d macos    # macOS desktop
flutter run -d android  # Android
flutter run -d ios      # iOS (requires macOS)
```

## 📱 Mobile & Desktop Apps

### Features
- **Intuitive Interface** - Clean, modern UI built with Flutter
- **Folder Management** - Add, remove, and manage sync folders
- **Real-time Sync** - Automatic synchronization with visual progress
- **Settings Panel** - Configure server URL, storage options, and debug mode
- **Folder Pairing** - Smart folder mapping with server folder selection
- **Cross-Platform** - Same app works on all platforms

### Supported Platforms
- ✅ **Android** - APK builds available
- ✅ **iOS** - Requires macOS for building
- ✅ **Windows** - Native Windows desktop app
- ✅ **Linux** - Native Linux desktop app
- ✅ **macOS** - Native macOS desktop app

## 📦 Available Commands

```bash
npm run setup          # Setup development environment
npm run build          # Build all clients
npm run build:all      # Build all clients (same as build)
npm run build:cli      # Build CLI only
npm run build:flutter  # Build Flutter only
npm run build:linux    # Build Linux platform
npm run build:windows  # Build Windows platform
npm run build:macos    # Build macOS platform
npm run build:android  # Build Android platform
npm run build:ios      # Build iOS platform
npm run start:server   # Start the server
npm run dev:server     # Start server in development mode
npm run install:cli    # Install CLI globally
npm run clean          # Clean build artifacts
npm run help           # Show available commands
```

## 🔧 Configuration

### Server Configuration

The server can be configured through environment variables or the settings panel in the mobile/desktop apps:

```bash
# Server settings
PORT=8080                    # Server port
HOST=0.0.0.0                # Server host
STORAGE_PROVIDER=local      # Storage provider (local or gdrive)
DEBUG_MODE=false            # Enable debug mode

# Google Drive (optional)
STORAGE_PROVIDER=gdrive     # Enable Google Drive storage
```

### Google Drive Setup (Optional)

1. **Create Google Cloud Project**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select existing
   - Enable Google Drive API

2. **Create Service Account**:
   - Go to IAM & Admin → Service Accounts
   - Create new service account
   - Download JSON credentials

3. **Configure Server**:
   ```bash
   # Set storage provider
   export STORAGE_PROVIDER=gdrive
   
   # Place credentials in server/config/
   mkdir -p server/config
   cp your-credentials.json server/config/gdrive.credentials.json
   ```

4. **Or use the Settings Panel**:
   - Open the mobile/desktop app
   - Go to Settings
   - Paste your Google Drive credentials JSON
   - Save settings

## 🔒 Security & Privacy

- **Self-Hosted** - Your data never leaves your server
- **No Data Collection** - No analytics or tracking
- **Local Storage** - Files stored on your own server by default
- **Optional Cloud** - Google Drive integration available if desired
- **HTTPS Ready** - Works behind reverse proxy with SSL certificates

### Production Deployment

For production use:

1. **Use HTTPS**:
   ```bash
   # Behind Nginx with SSL
   server {
       listen 443 ssl;
       server_name your-domain.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

2. **Environment Variables**:
   ```bash
   # Set secure environment
   export NODE_ENV=production
   export DEBUG_MODE=false
   ```

3. **Docker Deployment**:
   ```bash
   # Use Docker Compose for production
   docker compose -f docker-compose.prod.yml up -d
   ```

## 📁 Project Structure

```
nxss/
├── 📁 server/                 # Backend server (Node.js/Express)
│   ├── 📄 index.js           # Main server file
│   ├── 📁 services/          # Business logic
│   ├── 📁 storage/           # Storage providers
│   └── 📄 README.md          # Server documentation
├── 📁 clients/               # Client applications
│   ├── 📁 cli/               # Command-line client
│   │   ├── 📁 src/           # Source code
│   │   ├── 📁 dist/          # Built executable
│   │   └── 📄 README.md      # CLI documentation
│   └── 📁 flutter/           # Mobile & desktop apps (Flutter)
│       ├── 📁 lib/           # Dart source code
│       ├── 📁 android/       # Android platform files
│       ├── 📁 ios/           # iOS platform files
│       ├── 📁 linux/         # Linux desktop files
│       ├── 📁 windows/       # Windows desktop files
│       ├── 📁 macos/         # macOS desktop files
│       └── 📄 README.md      # Flutter app documentation
├── 📁 builds/                # Built clients by platform
│   ├── 📁 linux/             # Linux builds (CLI + Desktop)
│   ├── 📁 windows/           # Windows builds (CLI)
│   ├── 📁 macos/             # macOS builds (instructions)
│   ├── 📁 android/           # Android builds (instructions)
│   └── 📁 ios/               # iOS builds (instructions)
├── 📁 scripts/               # Build and setup scripts
│   ├── 📄 setup.sh           # Development setup
│   └── 📄 build-all.sh       # Build all clients
├── 📄 package.json           # Project configuration
└── 📄 README.md              # This file
```

## 🛠️ Development

### Prerequisites

- **Node.js** 18+ and npm
- **Flutter SDK** 3.0+ with desktop support
- **Git** for version control
- **Docker** (optional, for containerized development)

### Development Setup

1. **Clone and Install**:
   ```bash
   git clone https://github.com/your-username/nxss.git
   cd nxss
   npm install
   ```

2. **Enable Flutter Desktop**:
   ```bash
   # Enable desktop platforms
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   flutter config --enable-macos-desktop
   ```

3. **Setup Flutter App**:
   ```bash
   cd clients/flutter
   flutter pub get
   ```

4. **Start Development Server**:
   ```bash
   # Terminal 1: Start server
   cd server
   npm run dev

   # Terminal 2: Run Flutter app
   cd clients/flutter
   flutter run -d linux  # or windows, macos, android, ios
   ```

### Building for Production

```bash
# Build all platforms
npm run build

# Build specific platform
npm run build:linux
npm run build:windows
npm run build:android
npm run build:ios
```

### Docker Development

```bash
# Start with Docker
cd server
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter** - For the amazing cross-platform framework
- **Node.js** - For the robust server runtime
- **Express.js** - For the web framework
- **Docker** - For containerization support
- **All Contributors** - Thank you for your contributions!

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/nxss/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/nxss/discussions)
- **Documentation**: [Wiki](https://github.com/your-username/nxss/wiki)

## 🗺️ Roadmap

- [X] **Client/Server Pairing ** - Pair client and server with code
- [ ] **Web Interface** - Browser-based management interface
- [ ] **Mobile Push Notifications** - Real-time sync notifications
- [ ] **File Versioning** - Keep multiple versions of files
- [ ] **Selective Sync** - Choose which files to sync
- [ ] **Bandwidth Throttling** - Control sync speed
- [ ] **Conflict Resolution** - Handle file conflicts intelligently



---

**Made with ❤️ by the NXSS Team**




