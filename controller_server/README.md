# Server

## Dependencies
The server targets Linux and requires the X11 windowing system. On Wayland based
desktops, log out and choose an Xorg session.
Install the build tools and `libxdo`:

```bash
sudo apt install build-essential libxdo-dev
```

## Running
Use `cargo run` while inside the `server` directory:
```bash
cargo run
```

Enable logging:
```bash
RUST_LOG=info cargo run
```
You may use `debug` instead of `info` for more detailed logs.

For release builds use `cargo build --release`.