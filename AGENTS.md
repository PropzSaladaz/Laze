# Project notes

- `desktop_app` is the Tauri desktop UI and command layer; `controller_server` creates pairing invites and runs the authenticated server. `mobile_client` is the Flutter remote.
- The desktop name is stored in the Tauri app data directory as `desktop-name.json`. `desktop_app/src-tauri/src/commands.rs` loads it when creating each pairing invite. With no saved name, it uses the operating-system computer name or `Laze desktop`.
- Pairing QR codes include the desktop name. The mobile client stores that name with its pairing; a later desktop rename affects new pairing codes, not phones already paired.
- On mobile, Home lists saved pairings and connects by `serverId`. `ServerConnector.findServer` filters every connection path to that ID; `AppServiceWrapper` keeps the target for reconnects so a dropped connection cannot switch computers.
