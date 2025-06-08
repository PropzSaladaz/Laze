# Depedencies

On Linux it must be runned with X11 windowing system.
If you are on Wayland, you can log out and change to Ubuntu Xorg to use X11

# How to run

```
sudo apt install build-essential libxdo-dev
```

```
cargo run
```

Run with loggers (level info & lower):
```
RUST_LOG=info cargo run
```