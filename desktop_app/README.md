# 📦 Desktop App (Tauri)

This is the **desktop frontend** of the Mobile Virtual Device project, built using [Tauri](https://tauri.app/).  
It wraps a lightweight native application around a web-based interface to provide seamless local interaction with the mobile device emulation backend.


# 🎯 Purpose

This Tauri application serves as the **desktop control interface** for the mobile virtual device system. It allows users to:

- Start and stop the emulated mobile device server
- Visualize and control connected clients
- Monitor communication logs in real time
- Send actions/commands to the backend controller

It acts as a user-friendly control panel for development, debugging, and testing of the server-side logic.


# 🧰 Prerequisites

Before running this application, ensure the following are installed:

- [Rust](https://www.rust-lang.org/tools/install)
- [Node.js](https://nodejs.org/) (LTS recommended)
- [Tauri CLI](https://tauri.app/v1/guides/getting-started/setup)

### Install Tauri CLI

```bash
cargo install tauri-cli
```


# 🚀 How to Run

### 1. Install dependencies

```bash
npm install
# or
yarn install
```

### 2. Run in development mode

**Important**: Do **not** use VSCode’s integrated terminal.  
It may lead to issues related to dynamic libraries (see common errors below).  
Instead, use your system terminal (e.g., GNOME Terminal, Konsole, xterm):

```bash
npm run tauri dev
# or
yarn tauri dev
```

By default, the log level from **controller_server** is set to `info` level. You may change this in the `.env` file.

### 3. Build the production binary

```bash
npm run tauri build
# or
yarn tauri build
```



# ⚠️ Common Errors

### ❌ `undefined symbol: __libc_pthread_init, version GLIBC_PRIVATE`

**Cause**: This often occurs when using the **VSCode integrated terminal** on Linux.

**Solution**: Use your native terminal application instead (e.g., `gnome-terminal`, `xterm`, etc.).



# 🗂️ Directory Structure

    desktop_app/
    ├── src-tauri/         # Tauri Rust backend
    ├── src/               # Frontend source code (e.g., Vue, React)
    ├── package.json
    └── tauri.conf.json


