# LAN pairing and authentication (protocol 2)

## Using Laze

Update both the desktop and Android apps together. Older clients cannot control a protocol 2 server.

1. Start the desktop server on your local network and select **Pair phone**.
2. On Android, select **Pair computer** and allow camera access. Scan the desktop QR code. If the camera is unavailable, expand the pairing-code option on both devices and paste the code.
3. Pairing connects immediately. Future connections use **Connect**, remembered addresses and local discovery; another scan is unnecessary.
4. **Disconnect Client** ends a desktop session but keeps the pairing. **Forget phone** revokes the phone, closes its session and blocks reconnects. This list includes paired phones that are disconnected.
5. Android **Settings → Paired computers → Forget computer** removes its saved credential. Forgetting on Android does not revoke copies of that credential; use **Forget phone** on the desktop to revoke access there.

The desktop QR expires after three minutes, is single use, and is cancelled when closed, replaced, or the server stops. Keep it private: it authorizes the phone that possesses its random secret. A desktop with multiple network interfaces includes up to eight IPv4 addresses in the code.

Both apps must be reachable on the same LAN. Search does not provide Internet access or cross-subnet routing. Remembered addresses are tried first, followed by UDP discovery and a bounded fallback over two local private /24 ranges. The fallback does not infer arbitrary subnet masks.

## Security properties and limits

Authentication uses HMAC-SHA256 and HKDF-SHA256 from cryptographic libraries. Messages remain readable on the network, as requested; authentication detects tampering and rejects unauthenticated input and replay. Wi-Fi observers can still read commands and traffic patterns, and network peers can still interrupt or block traffic.

Trust belongs to a server identity and a per-phone secret, not an IP address, discovery advertisement, device name, or previous connection. Each reconnect requires proof from both parties and creates fresh session keys. UDP motion is accepted only while its authenticated TCP session is live. Stop, disconnect and revocation invalidate that session before returning.

A paired phone has the app's existing desktop-control privileges, including configured shell commands. Pairing is approval for those privileges. No account, cloud service, password server, or payload encryption is added.

- Desktop: Windows Credential Manager, macOS Keychain, or Linux Secret Service stores each phone's 32-byte secret. The local `paired-phones.json` contains server/device IDs, names, pairing times and random credential lookup IDs, not secrets. There is no plaintext-storage fallback.
- Phone: `flutter_secure_storage` stores the saved computers and secrets. Android credential preferences are excluded from backup and device transfer. Reinstall/restore can require pairing again.
- Unavailable or invalid credential storage fails closed. Local administrator/root compromise and copying an unlocked device's secrets are outside the network-authentication guarantee.
- Maximum 64 trusted phones/computers, 16 concurrent incomplete handshakes and the configured limit of live clients. TCP payload and handshake sizes and read deadlines are bounded.

## Wire format

All integer fields are big endian. IDs, nonces, keys and proofs in JSON use canonical Base64URL without padding. Protocol version is 2.

TCP is one socket for handshake, actions and desktop events. Every message is prefixed with its **u32 byte length**. JSON handshake bodies are at most 2,048 bytes. Authenticated input records are at most 1,080 bytes (1,024 payload + 56 overhead). Empty, oversized, incomplete, malformed or unauthenticated records close the client. Initial handshake reads have bounded idle and partial-frame deadlines. The phone allows five seconds per handshake frame.

UDP uses the authenticated record directly, without a length prefix, on advertised port 7876. If UDP cannot start or the phone cannot bind a UDP socket, motion uses authenticated TCP. UDP permits only a complete scroll action (2 bytes) or move action (3 bytes).

### Canonical transcripts

`T(label, fields...)` concatenates the UTF-8 label followed by all fields, each separately prefixed with its **u32 byte length**. Text fields below are UTF-8; nonce and session fields are decoded raw bytes.

**ClientHello**

```text
version, server_id, device_id, device_name, invite_id, client_nonce, proof
```

`invite_id` is the pending QR invitation for first pairing, or an empty string on reconnect. The client nonce is 32 random bytes.

```text
hello = T("laze-v2/client-hello",
          server_id, device_id, device_name, invite_id, client_nonce)
proof = HMAC(pair_secret, hello)
```

The desktop verifies the version, server identity, IDs, bounded name and proof. It has not admitted a controller yet.

**ServerChallenge**

```text
version, session_id, server_nonce, server_os, udp_port, proof
challenge = T("laze-v2/server-challenge",
              hello, server_nonce, session_id, server_os, u16(udp_port))
proof = HMAC(pair_secret, challenge)
```

The session ID is 16 random bytes; the server nonce is 32 random bytes. Server OS is `windows`, `linux` or `macos`. Port 0 means TCP motion fallback. The phone verifies this proof before continuing.

**ClientFinish**

```text
proof = HMAC(pair_secret, T("laze-v2/client-finish", challenge))
```

The desktop verifies finish, rechecks live server generation, invitation expiry/consumption or credential revocation, persists a new pairing, and establishes a session. An old incomplete handshake cannot survive stop/start or revocation. A newer session replaces previous sessions for that same phone.

**Session keys**

HKDF-SHA256: input key material is the 32-byte pairing secret, salt is `client_nonce || server_nonce`, and output length is 32 bytes for each of:

```text
info = T("laze-v2/session-key", server_id, device_id, session_id, label)
label = "client-tcp" | "client-udp" | "server-tcp"
```

### Authenticated records

```text
session_id[16] || sequence_u64[8] || payload || HMAC(session_key, preceding_bytes)[32]
```

TCP receive counters require the exact next sequence, starting at zero. UDP counters require a strictly greater sequence than the last accepted packet, starting at any nonnegative sequence to tolerate lost packets. Each direction and transport uses its own key/counter. Invalid tags, malformed payloads, session mismatch and rejected counters do not advance input counters.

Desktop event payloads are one byte: ready 253, revoked 252, disconnected 254, stopped 255. The phone publishes the connection only after verifying ready sequence 0 and saving credentials successfully. READY and subsequent events use one serialized writer.

Full action batches are validated before any action executes or acquires the shared controller lock. Command lengths are UTF-8 byte counts, maximum 255 bytes. The auth lock stays held through accepted dispatch; revocation/stop waits for an already accepted action to finish and prevents subsequent input.

## Validation

Fixed test credentials in `tools/protocol/auth-v2-vectors.json` are public fixtures only. Python's standard HMAC implementation independently generates matching handshake, HKDF and record vectors for Rust and Dart tests.

Run:

```sh
cargo test -p server --lib
cd mobile_client
flutter test --no-pub
```

Regression coverage includes unpaired peers, bad handshake proofs, incomplete handshakes, reused/expired/cancelled invitations, tampered messages, cross-direction/transport reflection, TCP/UDP replay, stale sessions, stop/start and revocation, persistence failure, fragmented/coalesced TCP messages, EOF cleanup, malformed batches, UTF-8 boundaries, actual loopback TCP/UDP ingress, and a disconnect racing READY. Windows credential storage is tested with a random isolated entry that is deleted afterwards. Test applications record input instead of moving the mouse or shutting down the computer.

Before release, manually scan a QR on Android, exercise mouse/scroll/keys/commands, reconnect after lock/unlock and IP changes, test Forget phone while moving, verify disconnected-phone revocation, and validate the signed release artifact. Camera UX, real-device latency, macOS/Linux/iOS integration and the release signing workflow are not established by Windows unit tests or debug builds.
