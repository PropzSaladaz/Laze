# Mobile Virtual Device

This project enables using a mobile phone as a remote pointing device for a desktop machine.
It is composed of:

- **controller_server** – a Rust application that listens for incoming connections and forwards
  the received bytes to a virtual input device.
- **desktop_app** – A Tauri desktop app that spins up `controller_server` and shows some UI to the user - current users connected, as well as connection time.
- **mobile_client** – A Flutter application that provides a mobile UI and communicates with **controller_server**

Each client initially connects to the server on port `7878`. The server then assigns
an individual port and spawns a thread to handle that connection. Input bytes sent by
the client are dispatched to the device application running on the server.

---

# Build and run

## Dependencies

```bash
sudo apt install build-essential libxdo-dev
```

## Build

Before running the project, you must generate all theme data shared across all projects:

```bash
node tools/theming/index.mjs design/tokens/tokens.json
```

## Run

To quickly spin up the app, you must run 2 components:

### 1. Desktop App

This will spin up the underlying server as well as the UI:

```bash
cd controller_server
cargo run
```

Run with logging:
```bash
RUST_LOG=info cargo run
```

### 2. Mobile client
```bash
cd mobile_client
flutter pub get
# generate json_serializable classes
dart run build_runner build
flutter run
```

For further information, please refer to the [project documentation](./docs/README.md)

