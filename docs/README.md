This document serves as the index for all project documentation.

# Running

## 1.1 Run Tauri app + Rust Server

```bash
cd desktop_app
npm run tauri dev
```

## 1.2 Run Rust Server (Optional)

If the first method isn't enough to diagnose any issue, you may need to run the underlying server manually.

```bash
sudo apt install build-essential libxdo-dev
cd controller_ server
cargo run
```

Run with logging:
```bash
RUST_LOG=info cargo run
```

## 2. Run Mobile Client

```bash
cd mobile_client
flutter pub get
# generate json_serializable classes
dart run build_runner build
flutter run
```