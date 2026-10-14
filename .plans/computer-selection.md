# Computer selection handoff

## Settled decisions

- Step 2 lets the user choose a saved computer from Home. Each card has its own Connect action; there is no global first-reachable Connect action.
- Targeted connection and automatic reconnects must stay on the selected `serverId`. Displaying the active computer name remains step 3.

## Relevant files and completed changes

- `mobile_client/lib/presentation/home/widgets/not_connected_screen.dart`: scrollable saved-computer cards and per-computer Connect actions; empty pairing state preserved.
- `mobile_client/lib/presentation/home/widgets/home_screen.dart`: passes the targeted callback.
- `mobile_client/lib/services/app_service_wrapper.dart`: remembers the selected target and uses it for reconnects and QR pairing success.
- `mobile_client/lib/services/server_connector.dart`: filters saved hosts, discovery, and subnet fallback to one `serverId`.
- `mobile_client/lib/presentation/pairing/paired_computers_screen.dart`: updates guidance to match the Home picker.
- Earlier desktop-name and onboarding changes in the working tree are preserved.

## Next bounded step and validation

- Manually verify two paired computers: each card connects only to its own desktop, and a dropped connection does not switch to the other.
- Static call-site review completed. `git diff --check` passed. Builds and tests have not been run, per user preference.

## Open questions

- Step 3 will display the active desktop name on the connected screen and in the shutdown confirmation.
