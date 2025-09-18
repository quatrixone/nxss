# NXSS Logo Design

## Logo Concept
The NXSS logo represents cross-platform file synchronization with:
- **Sync arrows** showing bidirectional data flow
- **Platform indicators** representing different devices
- **Modern design** with indigo color scheme matching the app theme

## Logo Files Created

### SVG Versions
- `clients/flutter/assets/logo.svg` - Main logo (64x64)
- `clients/flutter/assets/logo_icon.svg` - Icon version (32x32)  
- `clients/flutter/assets/logo_large.svg` - Large version (128x128)

### ASCII Art Version
```
    ╭─────────────╮
    │  NXSS LOGO  │
    │             │
    │    ↕        │
    │   ↕↕        │
    │  ↕ ↕        │
    │ ↕   ↕       │
    │↕     ↕      │
    │             │
    │  Cross-     │
    │  Platform   │
    │  File Sync  │
    ╰─────────────╯
```

## Design Elements

### Colors
- **Primary**: Indigo (#6366F1) - matches app theme
- **Secondary**: Blue (#4F46E5) - gradient accent
- **Text**: White - high contrast

### Symbolism
- **Sync Arrows**: Bidirectional file synchronization
- **Platform Rectangles**: Different devices/platforms
- **Connecting Line**: Data flow between platforms
- **Dots**: Individual files being synced

## Usage

The logo can be used in:
- App icons and splash screens
- Documentation and README files
- Marketing materials
- Website headers

## Implementation

To use the logo in the Flutter app, add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/logo.svg
    - assets/logo_icon.svg
    - assets/logo_large.svg
```

Then reference in code:
```dart
Image.asset('assets/logo.svg')
```
