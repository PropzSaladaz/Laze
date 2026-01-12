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

## Quick Start

1. **Desktop App**:
   ```bash
   cd desktop_app
   npm install
   npm run tauri dev
   ```

2. **Mobile Client**:
   ```bash
   cd mobile_client
   flutter pub get
   flutter run
   ```

For detailed documentation, see the [Documentation Hub](./docs/README.md).

## Theming

To regenerate theme tokens:

```bash
node tools/theming/index.mjs design-tokens/tokens/tokens.json
```

# Testing

This project includes comprehensive test suites for both the Rust server and Flutter client.

## Running Tests

### Controller Server (Rust)
```bash
cd controller_server
cargo test
```

### Mobile Client (Flutter)
```bash
cd mobile_client
flutter test
```

For detailed testing information, see [Testing Guide](./docs/testing.md)

## Continuous Integration

The project uses GitHub Actions to automatically run tests on every push and pull request:
- **Rust CI**: Builds and tests the controller_server
- **Flutter CI**: Builds and tests the mobile_client
- **Full CI**: Runs both test suites

All workflows ensure code quality and prevent regressions.

