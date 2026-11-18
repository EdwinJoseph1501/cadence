---
name: release-engineering
description: Use this skill when assembling release builds, packaging the macOS .app bundle, verifying code signatures, checking Git hygiene, and preparing public distribution materials for Cadence.
---

# Release Engineering for Cadence

## Purpose
Guide the deterministic packaging, code signing, validation, and release preparation of Cadence for local distribution and GitHub Releases.

## When to Use
- Working on Phase 7 milestones (GitHub Release and Distribution).
- Building optimized production binaries (`swift build -c release`).
- Generating and validating `build/Cadence.app`.
- Checking Git hygiene before tag creation or release handoffs.
- Documenting Gatekeeper / quarantine workarounds for ad-hoc signed releases.

## Practical Workflow
1. **Release Compilation**:
   - Compile optimized release binary: `swift build -c release`.
   - Verify binary size is within expectations (< 10 MB).
2. **Bundle Construction**:
   - Run `./scripts/build-app.sh release`.
   - Script generates standard macOS bundle structure:
     `Cadence.app/Contents/{MacOS/CadenceApp, Info.plist, Resources/}`.
3. **Code Signature & Integrity**:
   - Apply ad-hoc code signature: `codesign --force --deep --sign - build/Cadence.app`.
   - Validate signature: `codesign -v build/Cadence.app`.
   - Verify plist: `plutil -lint build/Cadence.app/Contents/Info.plist`.
4. **Git Hygiene & Cleanliness**:
   - Run `git status` to ensure no untracked build artifacts or `.DS_Store` files are present.
   - Verify `.gitignore` covers `.build/`, `build/`, `.swiftpm/`.
5. **Distribution Notes**:
   - Document ad-hoc Gatekeeper bypass for users downloading from GitHub:
     `xattr -cr /Applications/Cadence.app`.
   - Provide clear source-build instructions (`make app`) alongside binary releases.

## Project Constraints
- No automatic git commits, tags, pushes, or releases. Manual developer action is required for all publishing events.
- Zero dependencies on Xcode IDE; build pipeline must remain entirely functional via command-line Swift toolchain (`swift`, `codesign`, `plutil`).

## Verification Expectations
- `./scripts/verify.sh` completes all 5 gates with code 0.
- `codesign -v build/Cadence.app` returns clean without errors.
- Launch test: `open build/Cadence.app` runs cleanly on macOS.

## Common Mistakes to Avoid
- **Committing Build Artifacts**: Accidentally tracking `build/` or `.build/` files in Git.
- **Publishing Without Verification**: Creating release bundles without running the full `./scripts/verify.sh` suite.
- **Assuming Developer ID Signing**: Confusing local ad-hoc signatures (`codesign -s -`) with Apple Developer ID certificates needed for Gatekeeper-notarized distribution. Always clearly document ad-hoc signing limitations.
