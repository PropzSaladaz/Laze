# Desktop name handoff

## Settled decisions

- Item 1 is scoped to an editable desktop name and new pairing QR codes. Existing mobile pairings keep their saved name until they pair again.
- Keep the mobile connection and computer-selection flow out of this change.

## Relevant files and completed changes

- `desktop_app/src-tauri/src/commands.rs`: validate, load, and save the name in Tauri app data; use it for new pairing invites.
- `desktop_app/src-tauri/src/lib.rs`: register the name commands.
- `desktop_app/app/components/PairingPanel.tsx` and `.module.css`: name editor and save feedback in the existing paired-phones panel.
- Pre-existing mobile edits in `mobile_client/lib/presentation/onboarding/onboarding_screen.dart` and `mobile_client/lib/presentation/home/widgets/not_connected_screen.dart` are unrelated and preserved.

## Next bounded step and validation

- Manually verify in the desktop app that a saved name survives restart and appears in a newly generated QR code.
- Static review completed. `git diff --check` passed. Builds and tests have not been run, per user preference.

## Open questions

- A future feature could update the name on already-paired phones over an authenticated connection; it is outside this item.
