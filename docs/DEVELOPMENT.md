# Cadence Development Guide

This guide details the local setup, toolchain requirements, development workflow, and automated verification procedures for Cadence.

---

## 1. Environment & Prerequisites

Cadence is built natively for macOS using Swift 6 and standard Apple Developer tooling:

| Dependency | Minimum Version | Verified Local Environment |
| :--- | :--- | :--- |
| **macOS** | 14.0 (Sonoma)+ | macOS 27.0 (arm64 Apple Silicon) |
| **Architecture** | Apple Silicon (`arm64`) or Intel (`x86_64`) | Apple Silicon (`arm64`) |
| **Xcode Command Line Tools** | 16.0+ | Active at `/Library/Developer/CommandLineTools` |
| **Swift Toolchain** | Swift 6.0+ | Apple Swift 6.4 (swiftlang-6.4.0.34.1) |
| **swift-format** | 600.0+ | 604.0.0 (installed via Homebrew) |
| **Make** | Any standard BSD/GNU make | `/usr/bin/make` |

> **Note on Xcode**: Full `Xcode.app` is **not required**. The standalone Command Line Tools package contains all necessary compilers, SDK headers, and linkers to build, test, and bundle Cadence.

---

## 2. Quick Start

Clone or open the repository:
```bash
cd ~/Dev/projects/cadence
```

Run the complete verification suite to ensure your toolchain is working:
```bash
make verify
```

---

## 3. Development Workflow Commands

A `Makefile` is provided in the repository root to simplify common engineering tasks:

### Building
```bash
# Debug compilation
make build
# (Runs: swift build)

# Optimized production release compilation
make release
# (Runs: swift build -c release)
```

### Running Locally
```bash
# Compile and run the executable directly in your terminal/window session
make run
# (Runs: swift run CadenceApp)

# Package and launch the native .app bundle
make app
open build/Cadence.app
```

### Automated Testing
```bash
# Execute unit tests across all modules
make test
# (Runs: swift test)
```

Cadence uses the modern Swift Testing framework (`import Testing`). Tests run in parallel and typically complete in < 0.05 seconds.

### Code Style & Formatting
Cadence adheres strictly to Apple's official `swift-format` conventions configured in `.swift-format`:

```bash
# Check code formatting without modifying files (fails on violations)
make lint
# (Runs: swift-format lint --recursive Sources Tests)

# Automatically format all Swift source files in-place
make format
# (Runs: swift-format format --in-place --recursive Sources Tests)
```

### Cleaning
```bash
# Remove build artifacts and package caches
make clean
```

---

## 4. Packaging the Distributable Application & Archive

### Standalone macOS Application Bundle
To package Cadence into a standalone macOS Application bundle (`build/Cadence.app`):
```bash
make app
# Or directly:
./scripts/build-app.sh release
```

This script:
1. Compiles `CadenceApp` with release optimizations (`swift build -c release`).
2. Creates the bundle structure:
   - `build/Cadence.app/Contents/MacOS/Cadence`
   - `build/Cadence.app/Contents/Info.plist`
   - `build/Cadence.app/Contents/PkgInfo`
   - `build/Cadence.app/Contents/Resources/AppIcon.icns`
3. Applies an ad-hoc code signature (`codesign --force --deep -s -`) to satisfy macOS security policies.

### Creating a Distributable Release ZIP Archive
To produce a verified, distributable ZIP archive for release:
```bash
make package
# Or directly:
./scripts/package-release.sh
```

This script:
1. Executes `build-app.sh release`.
2. Validates binary executability, `AppIcon.icns`, `Info.plist` metadata, and `CFBundleIdentifier`.
3. Validates the code signature via `codesign --verify --deep --strict`.
4. Creates a distributable archive `build/dist/Cadence-v<version>-macos.zip` using `ditto -c -k --keepParent`, preserving Mach-O permissions and extended attributes.
5. Verifies archive integrity with `unzip -tq` and outputs file size and SHA-256 checksum.

---

## 5. End-to-End Verification Pipeline

Before submitting any code changes or proceeding between implementation phases, execute the verification suite:
```bash
./scripts/verify.sh
```

The script verifies:
1. `[1/5]`: `swift-format` linting across all sources and test files.
2. `[2/5]`: Execution and passing of all unit tests in `CadenceCoreTests` and `CadenceUITests`.
3. `[3/5]`: Successful debug build.
4. `[4/5]`: Successful release build and `.app` bundle assembly.
5. `[5/5]`: Code signature verification via `codesign -v`.
