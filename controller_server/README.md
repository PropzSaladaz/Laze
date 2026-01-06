# Controller Server (Rust)

Accepts client connections and emits virtual input to the OS. Designed for Linux/X11.

## Features
- TCP handshake on port 7878, per-client dedicated ports
- Per-client threads with graceful shutdown
- Virtual input via enigo (cross-platform)
- Structured logging with RUST_LOG

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Controller Server                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │ CommandListener │───▶│     Server      │───▶│   ClientPool    │ │
│  │  (commands.rs)  │    │    (core.rs)    │    │(client_pool.rs) │ │
│  └─────────────────┘    └─────────────────┘    └────────┬────────┘ │
│          ▲                                              │          │
│          │                                              ▼          │
│  ┌───────┴─────────┐                         ┌─────────────────┐   │
│  │  ServerHandler  │                         │     Client      │   │
│  │ (API for Tauri) │                         │  (per-client    │   │
│  └─────────────────┘                         │    thread)      │   │
│                                              └────────┬────────┘   │
│                                                       │            │
│                                                       ▼            │
│                                              ┌─────────────────┐   │
│                                              │MobileController │   │
│                                              │ (virtual input) │   │
│                                              └─────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | File | Responsibility |
|-----------|------|----------------|
| **Server** | `core.rs` | Accepts connections on port 7878, assigns dedicated ports |
| **ServerHandler** | `core.rs` | Public API for start/stop/events (used by Tauri) |
| **CommandListener** | `command_listener.rs` | Polls for commands via channels |
| **ClientPool** | `client_pool.rs` | Manages all client threads, handles termination |
| **Client** | `client_pool.rs` | Per-client thread, reads input bytes |
| **MobileController** | `mobile_controller.rs` | Translates bytes → mouse/keyboard actions |

---

### Thread Model

```
Main Thread (Tauri)
    │
    ├── CommandListener Thread
    │       └── Polls for start/stop commands
    │
    └── Server::start()
            │
            ├── Client Listener Thread
            │       └── Accepts new connections on :7878
            │
            ├── Termination Listener Thread
            │       └── Cleans up disconnected clients
            │
            └── Per-Client Threads (N)
                    └── Each handles one mobile device
```

---

### Connection Flow

```
1. Mobile connects to :7878
2. Server assigns dedicated port (7879, 7880, ...)
3. Server responds with: { port, os_type }
4. Mobile reconnects to dedicated port
5. Client thread spawned, reads input bytes
6. MobileController executes actions (mouse/keyboard)
```

---

### Event System

```rust
enum ServerEvent {
    ClientAdded(ClientInfo),   // → Tauri → Frontend UI
    ClientRemoved(ClientInfo), // → Tauri → Frontend UI
}
```

Events are broadcast via `tokio::sync::broadcast` channel.

---

## Source Files

```
src/
├── lib.rs                 # Public exports
├── main.rs                # Standalone CLI entry point
├── mobile_controller.rs   # Virtual input (enigo)
├── actions.rs             # Action enum (MouseMove, KeyPress, etc.)
├── keybinds.rs            # OS-specific key mappings
├── logger.rs              # Logging trait
└── server/
    ├── mod.rs
    ├── core.rs            # Server, ServerHandler, ServerConfig
    ├── client_pool.rs     # ClientPool, Client
    ├── command_listener.rs # CommandListener
    ├── command_sender.rs  # CommandSender
    ├── commands.rs        # ServerRequest, ServerResponse enums
    ├── application.rs     # Application trait
    └── utils.rs           # Helpers
```

---

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