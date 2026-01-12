# System Architecture

## High-Level Overview

The Mobile Virtual Device system allows a mobile phone to act as a remote input device for a desktop computer.

![System Architecture](./diagrams/Architecture.svg)

## System Components

### 1. Mobile Client (Flutter)
- **Responsibility**: Captures touch gestures and sensor data, converts them into command packets, and sends them to the server.
- **Discovery**: Uses UDP broadcast (or direct IP entry) to find the server.
- **Protocol**: TCP for reliable command transmission (mouse moves, clicks, scrolling).

### 2. Controller Server (Rust)
- **Responsibility**: Listens for connections, parses incoming commands, and simulates input events.
- **Concurrency**: Spawns a dedicated thread for each connected client.
- **Input Simulation**: Uses `enigo` (or `rdev`) to interact with X11/Xorg.
- **State**: Manages connected clients and broadcasts status updates to the Desktop App.

### 3. Desktop App (Tauri)
- **Responsibility**: Provides a GUI for the user to start/stop the server and view connected devices.
- **Backend**: Acts as a wrapper around the Rust `controller_server` library.
- **Frontend**: React/Next.js UI for status display.

## Network Protocol

### Handshake (Port 7878)
1. **Client** connects to Server TCP port 7878.
2. **Server** accepts and assigns a dedicated ephemeral port (e.g., 7879).
3. **Server** sends `HandshakeResponse` (JSON) containing the new port and OS info.
4. **Client** disconnects and reconnects to the new dedicated port.

### Command Format
Packets are sent as raw bytes or structured JSON/Protobuf (depending on implementation version).
- **Mouse Move**: `[type: 1, dx: i16, dy: i16]`
- **Click**: `[type: 2, button: u8]`
- **Scroll**: `[type: 3, amount: i16]`

## Data Flow

1. **Touch Event**: User drags finger on phone screen.
2. **Translation**: Flutter app calculates delta (dx, dy).
3. **Transmission**: Delta sent via TCP socket to dedicated server thread.
4. **Processing**: Server thread decodes packet.
5. **Execution**: Server calls `enigo.mouse_move_relative(dx, dy)`.
6. **OS Action**: Cursor moves on screen.
