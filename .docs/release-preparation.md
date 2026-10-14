# Android release preparation

Reviewed: 2026-10-13. Authentication implementation update: 2026-10-14.

Findings 1, 3, 4 and 6 are addressed by protocol 2 and its focused checks. Finding 2 now has required release signing and artifact certificate verification. Finding 7 has lockfile enforcement and a shared exact Flutter SDK pin. Finding 5 is partly addressed. Production certificate configuration, acceptance of the tagged release workflow, signed-release updates, and physical Android checks remain pending. See [authentication design and usage](../docs/authentication.md).

Source snapshot: repository HEAD `cfc0897fd9df99277cb8165e1e7d7230b2d8b9f4`, including the local working-tree changes present during the review. File and line references refer to that snapshot and may move as fixes are implemented.

**P1** findings should be resolved before public release. **P2** findings are important correctness or release-process improvements. Findings **1, 2, and 4** were the release blockers identified in this review; their code fixes are implemented, while release signing configuration and physical-device acceptance remain pending.

## 1. Client authentication is missing — P1

**Verdict:** Confirmed from source.

While the desktop server is enabled, any peer that can reach its listening ports can connect and send desktop-control commands. Network and firewall rules limit reachability, but the application protocol does not authenticate clients. TCP accepts arbitrary shell commands as an intended feature; UDP accepts mouse movement and scrolling without verifying a paired session.

Evidence:

- `controller_server/src/server/utils.rs:9` binds TCP listeners to all IPv4 interfaces.
- `controller_server/src/server/core.rs:349` accepts new clients without a pairing or approval check.
- `controller_server/src/server/client_pool.rs:313` accepts the dedicated connection without authenticating the peer.
- `controller_server/src/mobile_controller.rs:164` executes received Windows commands through `cmd /C`; the other-platform implementation uses `sh -c`.
- `controller_server/src/server/udp_input.rs:119` validates motion packet format and sequence, but does not authenticate its sender.

Release work:

- [x] Add explicit pairing with desktop approval and a persistent trusted-device identity.
- [x] Authenticate TCP and UDP traffic, tie motion to a live approved session, and reject replay. The user chose authentication-only traffic; encryption is not part of this implementation.
- [x] Verify that unpaired peers cannot dispatch commands or inject motion, and that revoked devices lose access, using recording applications and actual loopback ingress.
- [ ] Accept the QR/camera, reconnect and revocation flow on a physical Android phone with the rebuilt desktop.

## 2. Release signing can fall back to a debug certificate — P1

**Verdict:** Confirmed conditional release defect. This does not establish that any existing release was signed incorrectly.

If the Android keystore secret is missing, the release workflow skips keystore setup and continues. Gradle then selects the debug signing configuration. If the remaining build steps succeed, the workflow publishes those APK and AAB artifacts to a GitHub release. Correctly configured signing credentials avoid this fallback.

Correction to the initial review: debug keys are generated per environment; they are not one globally shared key. A debug certificate is unsuitable for store publishing and may differ between CI runs, preventing normal updates to sideloaded APKs.

Evidence: `.github/workflows/release-mobile.yml:55`, `mobile_client/android/app/build.gradle.kts:81`, and [Android signing guidance](https://developer.android.com/studio/publish/app-signing#debug-mode).

Release work:

- [x] Fail release builds when required keystore credentials are missing or invalid.
- [x] Remove automatic debug signing from the production release path.
- [x] Verify the final artifact's signing certificate against the expected release/upload certificate before publishing.
- [ ] Confirm that an installed release APK can update to the next release signed with the intended certificate.

The Gradle release guard checks required settings, keystore readability, and
the private key/password/alias before release work. CI requires the existing
signing secrets and an independently pinned `ANDROID_SIGNING_CERT_SHA256`
environment variable, then verifies both APK and AAB signatures before the
publish step. Focused checks use disposable keys and cover valid signatures,
wrong certificates, unsigned artifacts, and tampering. Production credentials
and update acceptance have not been exercised by these checks. Setup is
documented in [the mobile README](../mobile_client/README.md#android-release-signing).

## 3. Clean TCP closure is not handled — P2

**Verdict:** Confirmed by source inspection and an isolated socket check.

The TCP reader checks `bytes.is_empty()` on a fixed 1,024-byte buffer instead of checking the number of bytes read. When a peer closes its sending side cleanly, `read` returns zero repeatedly, but the buffer remains nonempty. The server loop consequently dispatches an empty slice and reads again, potentially spinning the CPU and retaining the client slot.

A received disconnect action exits correctly, and socket errors have a cleanup path. The defective case is EOF without that action, so the issue does not affect every disconnect.

Evidence: `controller_server/src/server/client_pool.rs:394`.

Release work:

- [x] Treat EOF as connection closure and return through client cleanup.
- [x] Verify that clean EOF releases the client slot and invalidates its session.

## 4. TCP framing and decoder errors can disable input across clients — P1

**Verdict:** Confirmed. Priority raised from P2 after reassessing the shared controller lock.

TCP reads can contain incomplete messages or several writes combined together. The server assumes each read contains complete input, while the decoder indexes and slices payloads without first checking their lengths. Device-info JSON is also parsed as though it must occupy one complete read.

The actual action decoder panicked on an incomplete action and an unknown action. Device-info JSON combined with a following action failed JSON parsing and then panicked in the action decoder. Complete valid actions combined together decoded successfully; coalescing alone is not always a failure.

The impact extends beyond the originating client: parsing occurs while the shared controller mutex is held. A panic poisons that mutex, and subsequent `lock().unwrap()` calls can fail for other TCP clients and UDP input too.

Evidence: `controller_server/src/actions.rs:64`, `controller_server/src/server/client_pool.rs:401`, `controller_server/src/server/client_pool.rs:443`, and [Rust mutex poisoning](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning).

Release work:

- [x] Define explicit framing for authentication/device information and action messages, with bounded payload sizes.
- [x] Buffer incomplete messages across reads.
- [x] Validate entire action batches before acquiring the shared controller lock; reject parse errors without invoking the legacy unchecked decoder on malformed data.
- [x] Verify split headers/JSON/action frames, combined records/actions, invalid action codes, and truncated payloads.
- [x] Verify that a bad authenticated client message cannot poison the controller lock or disable another valid client.

## 5. Discovery fallback scans fixed ranges and can wait indefinitely — P2

**Verdict:** Confirmed from source; no broad network sweep was run during validation.

Cached connections and UDP discovery can work on other network ranges. The fallback sweep is restricted to `192.168.0.x` through `192.168.254.x`, probing up to 65,280 addresses. It misses `192.168.255.x`, `10.x`, and private `172.16` through `172.31` networks.

Connection entries are cleared when a new search starts, but accumulate within a search and are revisited by each batch. The fallback's dedicated-port wait can also repeat indefinitely if a peer accepts the base TCP connection without completing the expected handshake.

Evidence: `mobile_client/lib/services/server_connector.dart:193`, `mobile_client/lib/services/server_connector.dart:342`, `mobile_client/lib/services/server_connector.dart:391`, and `mobile_client/lib/services/server_connector.dart:458`.

Release work:

- [ ] Derive arbitrary local subnet masks if broader subnet scanning is needed. Current fallback probes up to two local private /24 ranges, with batches of 32 and per-batch cleanup; it does not scan an entire 192.168 range.
- [x] Add handshake deadlines and cancellation/generation checks for pending connection attempts.
- [x] Provide a QR/pasted pairing-code route with explicit desktop address hints when discovery is unavailable.
- [ ] Verify fallback behavior on supported private network ranges and when a host never finishes the handshake.

## 6. Terminal-command lengths use text units rather than UTF-8 bytes — P2

**Verdict:** Confirmed using the actual mobile encoding logic and Rust action decoder.

The mobile client prefixes commands with Dart's `command.length` (UTF-16 code units), then sends a UTF-8 payload. The server interprets the prefix as a byte count. For example, `echo cafe` produced a prefix of 9 and 9 payload bytes; `echo café` produced a prefix of 9 and 10 payload bytes. The latter panicked in the real Rust decoder.

Depending on where the boundary falls, incorrect lengths can truncate text or leave bytes to be interpreted as further actions. This can trigger finding 4's wider shared-lock failure.

Evidence: `mobile_client/lib/data/services/input.dart:128` and `controller_server/src/actions.rs:113`.

Release work:

- [x] Encode to UTF-8 first and prefix the encoded byte count.
- [x] Enforce the current one-byte length field's maximum of 255 payload bytes.
- [x] Validate payload length and UTF-8 on the server without panicking.
- [x] Verify accented commands, malformed UTF-8, and the byte-length boundary.

## 7. Release dependency locking and SDK alignment need attention — P2

**Status:** Dependency locking and SDK alignment are implemented. Acceptance of the tagged signed release remains pending.

The original review found that `mobile_client/pubspec.lock` was excluded from version control. Its ignore rule is now removed, and the existing lockfile is included in the repository changes. Dependency versions and hosted package hashes are preserved. All mobile CI and release jobs resolve with `flutter pub get --enforce-lockfile` and use `--no-pub` for subsequent Flutter commands.

Flutter 3.47.4 stable is pinned once in `mobile_client/pubspec.yaml` as `environment.flutter`. All four CI/release jobs use `flutter-version-file` to read that value. The Dart lower bound now matches the existing lockfile's 3.12.0 requirement; the pinned Flutter SDK supplies Dart 3.13.3. A shared Python guard verifies the exact stable Flutter version in CI and the local release script, since Pub only enforces the Flutter constraint's lower bound.

Evidence: `mobile_client/pubspec.yaml`, `mobile_client/pubspec.lock`, both mobile workflows, `scripts/check_flutter_version.py`, and `scripts/build-release.sh`. See [Dart's lockfile enforcement](https://dart.dev/tools/pub/cmd/pub-get#--enforce-lockfile) and [flutter-action's version-file support](https://github.com/subosito/flutter-action#use-version-from-pubspecyaml-or-fvm-config).

Release work:

- [x] Include `mobile_client/pubspec.lock` and enforce its resolution in release CI.
- [x] Choose and pin one supported Flutter SDK baseline for development and release validation.
- [ ] Review and commit the intended local Android/dependency changes before tagging a release.
- [ ] Validate the exact release commit through the release workflow and test its signed artifact on Android.

## Validation record

The reassessment combined source inspection, Git metadata checks, official signing and dependency guidance, and isolated Dart/Rust checks. The local review helper independently reviewed findings 3 and 6; its conclusions were checked against the source and reproductions.

The isolated checks exercised the mobile encoder with connection dependencies replaced by stubs, imported the actual Rust action decoder, and used a separate ephemeral loopback socket for EOF behavior. They reproduced the Unicode length mismatch, decoder panics, mutex poisoning, and repeated zero-byte reads. ASCII commands and complete combined actions passed decoding.

No live desktop input or shell-command dispatch was used for that review. The review did not change application source or perform a full release build, published-artifact signing audit, or phone UI test. Implementation and validation since that review are recorded below.

### Implementation validation — 2026-10-14

The earlier validation record describes the original review. Protocol 2 changes were developed and checked in an isolated source copy; existing local Android and desktop configuration changes were preserved.

- `cargo test -p server --lib`: 31 passed, 1 existing display-dependent test ignored.
- `flutter test --no-pub`: 35 passed, including 9 new protocol/storage/UTF-8 tests.
- Desktop Next production export, Tauri Rust check/build and Android debug APK build succeeded on Windows. The SDK environment was supplied explicitly to the build process, using the PC's existing user settings.
- Flutter analysis reports no errors or new diagnostics. It still exits 1 for five pre-existing warnings and two pre-existing info diagnostics in unchanged files.
- An independent security reviewer found a READY/teardown writer race. It was corrected and a repeated loopback concurrency regression test was added.
- Broader `cargo test -p server` also ran library and binary tests but fails on two pre-existing documentation examples in unchanged `command_listener.rs` and `command_sender.rs`. The Rust CI's `--lib` test command passes.

Authentication checks use isolated recording applications, public fixed test keys, ephemeral sockets and a disposable Windows Credential Manager entry. They do not move the desktop pointer or execute received controller commands. The nearest existing Rust test still invokes its pre-existing `echo test` command.

Physical Android QR scanning, lock/unlock behavior, real-device latency, signed release builds and macOS/Linux/iOS integration remain unverified. Production signing configuration, acceptance of the tagged release workflow, and update acceptance remain pending after findings 2 and 7's code fixes.

### Physical QR pairing follow-up — 2026-10-14

The first phone attempt exposed inherited nonblocking sockets on Windows. Client workers now restore blocking mode before reading the handshake. Both apps rebuilt successfully, the updated Android app was installed with data preserved, and the user confirmed that a fresh QR scan connects. One trusted phone was persisted. Input/latency, lock/unlock reconnect, revocation and signed-release acceptance remain pending.

### Drag cleanup

Mouse-down ownership is tracked per authenticated session. EOF, explicit
disconnect, desktop removal, revocation, and server stop release that session's
held buttons; a button held by another session stays pressed. Teardown paths
are serialized so socket cleanup cannot discard an administrative disconnect
event. On mobile, pointer cancellation, backgrounding, fullscreen closure,
and touchpad disposal cancel pending long presses and release active drags.
Cleanup sends to the original connection so it cannot release a drag on a
later connection.

Focused checks passed: three button-ownership tests, five authenticated
client-pool tests (including the READY/disconnect race), and nine Flutter
gesture tests. These use recording applications and injected input senders,
without generating desktop mouse input. Physical-phone drag interruption and
Wi-Fi-loss acceptance remain pending.

