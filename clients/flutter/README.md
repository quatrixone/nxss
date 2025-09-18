# NXSS: Cross-Platform File Sync System

Flutter-based mobile and desktop applications for NXSS file synchronization.

> **Location**: `clients/flutter/` - This app is now part of the clients directory for better organization.

## 📱 Supported Platforms

- **Mobile**: Android, iOS
- **Desktop**: Windows, Linux, macOS

## 🚀 Quick Start

### Development Setup

```bash
# Install Flutter dependencies
flutter pub get

# Enable desktop platforms
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop

# Create platform folders
flutter create --platforms=windows,linux,macos .
```

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d linux    # Linux desktop
flutter run -d windows  # Windows desktop (on Windows)
flutter run -d macos    # macOS desktop (on macOS)
flutter run -d android  # Android device/emulator
flutter run -d ios      # iOS device/simulator (on macOS)
```

## 🏗️ Building

### Release Builds

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release

# Linux Desktop
flutter build linux --release

# Windows Desktop (on Windows)
flutter build windows --release

# macOS Desktop (on macOS)
flutter build macos --release
```

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/
│   ├── login_screen.dart  # User authentication
│   └── files_screen.dart  # File management
└── services/
    ├── api.dart           # Server communication
    └── session.dart       # Local storage
```

## ⚙️ Configuration

### Server URL

The app automatically detects the server URL based on platform:

- **Android Emulator**: `http://10.0.2.2:8080`
- **iOS Simulator**: `http://127.0.0.1:8080`
- **Desktop**: `http://127.0.0.1:8080`

You can change this on the login screen.

### Authentication

- Email/password authentication
- JWT token storage
- Automatic login persistence

## 🎨 Features

### File Management
- Browse synchronized files
- Upload new files
- Download files
- Delete files
- Real-time sync status

### User Interface
- Material Design
- Dark/Light theme support
- Responsive layout
- Cross-platform consistency

## 🔧 Development

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2                    # HTTP requests
  shared_preferences: ^2.2.3      # Local storage
  flutter_hooks: ^0.20.5          # State management
  file_picker: ^8.0.0             # File selection
  path: ^1.9.0                    # Path utilities
```

### Code Structure

- **Screens**: UI components and user interactions
- **Services**: Business logic and API communication
- **Models**: Data structures and type definitions

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 🐛 Troubleshooting

### Common Issues

1. **"Server not reachable"**
   - Check server URL in login screen
   - Ensure server is running
   - Check network connectivity

2. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Flutter version compatibility

3. **Platform-specific issues**
   - Ensure platform is enabled: `flutter config --enable-<platform>-desktop`
   - Check platform requirements (Android SDK, Xcode, etc.)

### Debug Mode

```bash
# Run in debug mode with verbose output
flutter run --verbose

# Check Flutter doctor
flutter doctor -v
```

## 📦 Distribution

### Android
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### iOS
- App: `build/ios/Release-iphoneos/Runner.app`
- IPA: Create through Xcode

### Desktop
- Linux: `build/linux/x64/release/bundle/`
- Windows: `build/windows/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`