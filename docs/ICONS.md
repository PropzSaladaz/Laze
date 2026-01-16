# Icon Generation Guide

This guide explains how to generate and update the application icons for both the Mobile Client (Flutter) and Desktop App (Tauri).

## Prerequisites

Ensure you have a source icon image (recommended: 1024x1024 PNG). 
The commonly used path for the source icon is `design-tokens/icon.png`.

## 📱 Mobile Client (Flutter)

The mobile client uses the `flutter_launcher_icons` package to generate icons for Android and iOS.

### Configuration
The configuration is located in `mobile_client/pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "../design-tokens/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "../design-tokens/icon.png"
```

### Command
Run the following command from the `mobile_client` directory:

```bash
cd mobile_client
dart run flutter_launcher_icons
```

## 🖥️ Desktop App (Tauri)

The desktop app uses the Tauri CLI's built-in icon generator.

### Command
Run the following command from the `desktop_app` directory, pointing to your source image:

```bash
cd desktop_app
npm run tauri icon ../design-tokens/icon.png
```

This will automatically generate all necessary icon sizes (png, ico, icns) and place them in `desktop_app/src-tauri/icons/`.
