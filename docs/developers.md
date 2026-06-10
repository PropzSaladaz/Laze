# Developer Guide

For contributors and maintainers. This guide orients you in the repo, shows how to build/run each component, and links to specialized docs.

## Repository layout

```
mobile-virtual-device/
├─ README.md                 # Root overview
├─ controller_server/        # Rust server: networking + virtual input
│  └─ README.md
├─ desktop_app/              # Tauri desktop UI that manages the server
│  └─ README.md
├─ mobile_client/            # Flutter client for mobile devices
│  └─ README.md
├─ docs/                     # Documentation (this folder)
└─ design-tokens/            # Design tokens and assets
```

## Prerequisites

- Linux desktop (X11/Xorg session) for the server
- Rust toolchain + Cargo
- Node.js + npm (for the desktop app)
- Flutter SDK + platform toolchains (Android Studio / Xcode as needed)

See per-app READMEs for platform-specific packages.

## Quickstart

#### 1. [Recomended] Start desktop GUI
```bash
cd desktop_app
npm install
npm run tauri dev
```

#### 1.1 [Optional] Start backend server directly
Instead of running the previous command, which opens both GUI and backend server, you can start the backend server directly without GUI:
```bash
cd controller_server
cargo run
```

#### 2. Start mobile app
```bash
# start mobile app
cd mobile_client 
flutter pub get 
flutter run
```

## Architecture & flows

![](diagrams/Architecture.svg)

- [Use cases and sequence diagrams](./use-cases.md)

## Networking

- Initial handshake on TCP port 7878; server assigns a dedicated port per client.
- All devices must be on the same LAN; ensure firewalls allow inbound connections to the server.

## Logging

- Rust server: use RUST_LOG=info (or debug)
- Tauri/Flutter: see per-app README for enabling verbose logs

## Troubleshooting

- **Wayland sessions are not supported for virtual input; use an Xorg session.**
- If the desktop app fails to start the backend, start the Rust server manually to verify it runs.
- If the mobile app cannot find the server, ensure you are on Wi‑Fi and on the same subnet; check firewall rules.

## Releasing

The version is committed to the repo and is the single source of truth. One
script keeps every manifest in sync, and CI refuses to build a release whose
manifests don't match the tag — so the published artifacts (including the
desktop bundle filenames, e.g. `Laze.Server_1.1.0_x64...`) always match.

Manifests kept in sync:

- `mobile_client/pubspec.yaml` — Flutter `build-name` + `build-number`
- `desktop_app/package.json` — npm/Tauri frontend
- `desktop_app/src-tauri/tauri.conf.json` — drives desktop bundle/asset names
- `desktop_app/src-tauri/Cargo.toml` — `[package]` version

To cut a release `X.Y.Z`:

```bash
scripts/set-version.sh X.Y.Z          # write the version into every manifest
git commit -am "chore(release): X.Y.Z"
git tag vX.Y.Z
git push --follow-tags
```

Pushing a `vMAJOR.MINOR.PATCH` tag triggers both
[release-mobile.yml](../.github/workflows/release-mobile.yml) and
[release-desktop.yml](../.github/workflows/release-desktop.yml). Each first runs
a `verify-version` job (`scripts/set-version.sh --check <tag>`) that fails the
release if any manifest version differs from the tag.

Notes:

- Use the full `vX.Y.Z` form — the stricter trigger means a partial tag like
  `v1.1` won't start a release.
- The Android `versionCode` is derived deterministically from the semver
  (`MAJOR*10000 + MINOR*100 + PATCH`), so it always increases with the version.
- For a correctly versioned local build, run `scripts/set-version.sh X.Y.Z`
  first (no commit needed for local testing).

## Per-app documentation

- [Controller Server (Rust)](../controller_server/README.md)
- [Desktop App (Tauri)](../desktop_app/README.md)
- [Mobile Client (Flutter)](../mobile_client/README.md)
