# Controller Server (Rust)

Always-on server that accepts client connections and emits virtual input to the OS.

## Features

- UDP broadcast discovery on port 7877
- TCP handshake on port 7878, per-client dedicated ports
- Per-client threads with graceful shutdown
- Virtual input via `enigo` (cross-platform)
- Structured logging with `RUST_LOG`

---

## Architecture

```mermaid
graph TD
    SH["ServerHandler (core.rs)"]
    CL["CommandListener (command_listener.rs)"]
    S["Server (core.rs)"]
    CP["ClientPool (client_pool.rs)"]
    C["Client (per-client thread)"]
    MC["MobileController (mobile_controller.rs)"]
    DL["DiscoveryListener (discovery.rs)"]

    SH -->|"sends requests via channel"| CL
    CL -->|"command_parser callback"| S
    S -->|"manages"| CP
    CP -->|"spawns"| C
    C -->|"translates bytes →"| MC
    SH -->|"owns"| DL
    S -->|"broadcasts ServerEvent"| SH
```

### Core Components

| Component | File | Responsibility |
|-----------|------|----------------|
| **Server** | `core.rs` | Accepts TCP connections on port 7878, assigns dedicated ports |
| **ServerHandler** | `core.rs` | Public API for start/stop/events (used by Tauri) |
| **CommandListener** | `command_listener.rs` | Polls for commands from Tauri via channel; dispatches to `Server` |
| **ClientPool** | `client_pool.rs` | Manages all client threads, handles termination |
| **Client** | `client_pool.rs` | Per-client thread, reads input bytes |
| **MobileController** | `mobile_controller.rs` | Translates bytes → mouse/keyboard actions via `enigo` |
| **DiscoveryListener** | `discovery.rs` | UDP broadcast responder so clients can auto-discover the server |

---

### Thread Model

```mermaid
graph TD
    Main["Main Thread (Tauri)"]
    DL["Discovery Listener Thread UDP :7877"]
    ST["Server Thread"]
    CL["CommandListener Thread"]
    CLL["Client Listener Loop :7878"]
    TL["Termination Listener Thread"]
    PCT["Per-Client Threads :7879, :7880, …"]

    Main -->|"start_discovery_listener()"| DL
    Main -->|"thread::spawn"| ST
    ST -->|"command_listener.listen()"| CL
    ST -->|"start_client_listener()"| CLL
    CP -->|"start_termination_listener()"| TL
    CLL -->|"Client::launch_new_client()"| PCT

    CP["ClientPool"]
    ST --> CP
```

---

### Connection Flow

```mermaid
sequenceDiagram
    participant M as Mobile Client
    participant DL as DiscoveryListener :7877
    participant S as Server :7878
    participant CP as ClientPool
    participant C as Client :7879+

    M->>DL: UDP broadcast "DISCOVER_MOBILE_CONTROLLER"
    DL-->>M: "MOBILE_CONTROLLER:<ip>:7878"
    M->>S: TCP connect
    S->>CP: add(addr, app)
    CP->>C: spawn thread, bind :7879
    CP-->>S: port 7879
    S-->>M: JSON { port: 7879, server_os }
    M->>C: TCP connect :7879
    M->>C: JSON { device_name }
    Note over C: emits ClientUpdated event
    loop Command Loop
        M->>C: input bytes
        C->>C: MobileController.execute()
    end
```

---

### Event System

The server exposes a `Receiver` after startup to allow whoever initialized the server to listen to events.

This is useful for the Tauri frontend.
These are the current supported events:

```rust
enum ServerEvent {
    ClientAdded(ClientInfo),    // new client connected  → UI
    ClientRemoved(ClientInfo),  // client disconnected   → UI
    ClientUpdated(ClientInfo),  // device name received  → UI
}
```

Events are broadcast via `tokio::sync::broadcast` channel from `ClientPool` → `ServerHandler` → Tauri frontend.

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
RUST_LOG=debug cargo run
```

Release build:
```bash
cargo build --release
```

## Configuration

- Handshake port: `7878` (see `src/main.rs`)
- Discovery port: `7877` (UDP, hardcoded in `discovery.rs`)
- Max clients: configurable via `ServerConfig::new(port, max_clients)`

## Graceful Shutdown

The desktop app (or CLI) sends `TerminateServer` → `CommandListener` sets `terminate_signal = true` → `ClientPool::shutdown()` signals all client threads and waits for exit.

## Troubleshooting

- **Virtual input doesn't work**: Ensure you're on an Xorg session (not Wayland).
- **Permission errors**: Run from a normal user session with Xorg.
- **Port already in use**: Change the port in config or free the port.
- **Clients can't auto-discover**: Check firewall rules for UDP port 7877; clients can also connect manually by IP.
