# Mobile Client (Flutter)

Connects to the Controller Server and sends input (e.g., pointer movement, actions).

## Features
- Discovers server on local network (handshake on port 7878)
- Sends input bytes to dedicated per‑client port
- Basic connection status and error feedback

## Setup

Use the exact stable Flutter SDK pinned by `environment.flutter` in
`pubspec.yaml` (currently **3.47.4**, with Dart **3.13.3**). Python 3 is required
for the SDK version check; on macOS/Linux use `python3` if `python` is unavailable.
CI and release jobs read the same pin, and `scripts/build-release.sh` checks it
before building locally.

```bash
cd mobile_client
python ../scripts/check_flutter_version.py
flutter pub get --enforce-lockfile
# If using codegen (json_serializable), generate:
dart run build_runner build --delete-conflicting-outputs
```

`pubspec.lock` belongs in version control. Setup, CI, and release builds use
`--enforce-lockfile` to reject an invalid resolution or changed package hashes.
Later Flutter commands use `--no-pub` so they use the checked resolution.
If setup fails, verify the SDK pin and restore the intended lockfile. For an
intentional dependency update, resolve it with the pinned SDK, review both
`pubspec.yaml` and `pubspec.lock`, and run the checks before committing.

## Run
```bash
flutter run --no-pub
```
Choose your device/emulator from the Flutter device list.

## Build
- Android release: `flutter build apk --release --no-tree-shake-icons --no-pub`
- Android development: `flutter build apk --debug --no-pub`
- iOS: `flutter build ios --no-tree-shake-icons --no-pub`
- Web/Desktop: supported by Flutter; functionality may vary

### Android release signing

Android release APK and AAB builds require all four signing settings. Set
`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD`, or create
an untracked `android/key.properties` with `storeFile`, `storePassword`,
`keyAlias`, and `keyPassword`. Environment variables take precedence. Relative
keystore paths resolve from `android/app`. Missing settings, an unreadable
keystore, incorrect passwords, or a missing alias fail the release build.
For development without a release key, use `flutter build apk --debug --no-pub`.

The GitHub environment **Laze Android App Deployment** requires the existing
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and
`ANDROID_KEY_PASSWORD` secrets, plus the environment variable
`ANDROID_SIGNING_CERT_SHA256`. Set this variable to the SHA-256 fingerprint of
the intended release/upload certificate, independently checked against the
established signing certificate. Do not derive the expected fingerprint from
the artifact being published. Hex digits with or without colons are accepted.
For Play App Signing, this is the upload certificate used for this workflow's
APK/AAB, rather than Google's distribution certificate.

You can inspect the intended keystore certificate locally with
`keytool -list -v -keystore /path/to/release.jks -alias your-alias` (it prompts
for the password). Before publishing, CI verifies each artifact's signature
and certificate fingerprint; unsigned, modified, or unexpected signers fail
the job. The verifier uses the Android SDK's `apksigner` for APKs and Java's
JAR signature verification for AABs.

Run the focused verification checks with Java 17+, an Android SDK in
`ANDROID_HOME`, and `python scripts/test_android_signing.py` from the repository
root. These checks generate disposable keys and artifacts.

## Configuration
- Default handshake port: 7878 (see `lib/services/server_connector.dart`)
- Both phone and server must be on the same Wi‑Fi network

## Troubleshooting
- Cannot find server: ensure Wi‑Fi is enabled and on same subnet; verify server is listening on 7878
- Connection rejected: server may be at capacity; check server logs
- Timeouts: verify firewall rules and network connectivity
