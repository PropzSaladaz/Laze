# Mobile Client

This Flutter application connects to the Rust server and sends touch events as
mouse movement data.

## Setup
```bash
flutter pub get
# generate json_serializable classes
dart run build_runner build
```
If you encounter errors while generating code, try running:
```bash
flutter pub upgrade
```

Run the app on a connected device or emulator with:
```bash
flutter run
```
