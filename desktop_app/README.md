# Desktop App (Tauri)

Desktop control panel for the Mobile Virtual Device system. Starts/stops the Rust server and shows connected clients.


## Overview

- Provides a UI to manage the backend server
- Monitors logs and connection status
- Cross‑platform where Tauri supports, but server features target Linux/X11


## Prerequisites

- Rust toolchain (for Tauri backend)
- Node.js (LTS) and npm
- Tauri CLI

Install CLI:

```bash
cargo install tauri-cli
```

Platform notes:

- Linux: ensure system dependencies required by Tauri are installed (see https://tauri.app)
- macOS/Windows: app UI runs, but the Rust controller server features may be Linux‑specific


## Run (development)

```bash
cd desktop_app
npm install
npm run tauri dev
```

If you see GLIBC/terminal issues on Linux, use a native terminal (not VS Code integrated terminal).


## Build (production)

```bash
npm run tauri build
```

Artifacts are under `src-tauri/target/` per platform.


## Environment

- Server port defaults to 7878 (see `src-tauri/src/lib.rs`); adjust in code if needed
- The desktop app sets RUST_LOG for the server. You can override with `.env` or shell env.



