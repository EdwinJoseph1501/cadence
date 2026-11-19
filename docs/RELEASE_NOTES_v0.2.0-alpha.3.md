# Cadence v0.2.0-alpha.3

## What changed

- Adjust a running or paused countdown by −1, +1, or +5 minutes without restarting it. Elapsed progress is preserved, and active completion notifications and the Dock badge update to the new deadline.
- See the expected local finish time beneath the running countdown. The menu bar also shows the projected finish time if a paused timer resumes now.
- Reach the adjustments from the main window, menu bar dropdown, or Timer menu. `Command-Shift-[` removes a minute and `Command-Shift-]` adds one.
- Give alpha installers version-specific ZIP and DMG filenames, with checksums for both artifacts. The app bundle is build 3 of version 0.2.0.

## Verification

- 87 automated tests across 10 suites, including new adjustment, persistence, bounds, and notification scheduling tests.
- Full `scripts/verify.sh` gate: Swift formatting, tests, debug build, release bundle, and code signature.
- Release ZIP and DMG integrity checks through `scripts/package-release.sh`.

## Distribution

The app is ad-hoc signed and has not been notarized with an Apple Developer ID. On first launch after download, macOS may require Control-clicking Cadence.app and choosing **Open**.
