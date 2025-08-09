# Mobile Client (Flutter)

Connects to the Controller Server and sends input (e.g., pointer movement, actions).

## Features
- Discovers server on local network (handshake on port 7878)
- Sends input bytes to dedicated per‑client port
- Basic connection status and error feedback

## Setup
```bash
cd mobile_client
flutter pub get
# If using codegen (json_serializable), generate:
dart run build_runner build
```
If codegen fails:
```bash
flutter pub upgrade
```

## Run
```bash
flutter run
```
Choose your device/emulator from the Flutter device list.

## Build
- Android: `flutter build apk`
- iOS: `flutter build ios`
- Web/Desktop: supported by Flutter; functionality may vary

## Configuration
- Default handshake port: 7878 (see `lib/services/server_connector.dart`)
- Both phone and server must be on the same Wi‑Fi network

## Troubleshooting
- Cannot find server: ensure Wi‑Fi is enabled and on same subnet; verify server is listening on 7878
- Connection rejected: server may be at capacity; check server logs
- Timeouts: verify firewall rules and network connectivity
