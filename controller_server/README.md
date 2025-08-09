# Controller Server (Rust)

Accepts client connections and emits virtual input to the OS. Designed for Linux/X11.

## Features
- TCP handshake on port 7878, per-client dedicated ports
- Per-client threads with graceful shutdown
- Virtual input via libxdo (X11)
- Structured logging with RUST_LOG

## Prerequisites
Linux (Xorg session). Install toolchain and libraries:

- Rust + Cargo: https://www.rust-lang.org/tools/install
- System packages (Debian/Ubuntu):
  ```bash
  sudo apt update && sudo apt install -y build-essential libxdo-dev
  ```
- System packages (Fedora/RHEL):
  ```bash
  sudo dnf install -y @development-tools libxdo-devel
  ```
- System packages (Arch):
  ```bash
  sudo pacman -S --needed base-devel xdotool
  ```

## Build & Run
```bash
cd controller_server
cargo run
```
With logs:
```bash
RUST_LOG=info cargo run
# or
RUST_LOG=debug cargo run
```
Release build:
```bash
cargo build --release
```

## Configuration
- Default handshake port: 7878 (see `src/main.rs` and server config)
- Max clients: configurable via `ServerConfig::new(port, max_clients)`

## Graceful Shutdown
- The desktop app or CLI triggers shutdown; server signals client threads and waits for termination.

## Troubleshooting
- "Virtual input doesn't work": Ensure you're on an Xorg session (not Wayland).
- "Permission errors": Some desktop environments may require input simulation permissions; try running from a normal user session with Xorg.
- "Port already in use": Change the port in config or free the port.