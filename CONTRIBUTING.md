# Contributing to Cadence

Thank you for your interest in contributing to Cadence! We welcome bug fixes, documentation improvements, and thoughtful refinements that align with the product's vision.

---

## 1. Product Philosophy & Scope Boundaries

Cadence is engineered as a focused, tactile, native macOS countdown utility with zero third-party dependencies.

To maintain near-instant launch times, minimal memory footprint (<30 MB idle), and architectural purity, the following features are **explicitly out of scope** for v1.0:

- **No external dependencies**: Cadence relies exclusively on Apple system frameworks (`SwiftUI`, `AppKit`, `Metal`, `UserNotifications`).
- **No telemetry or analytics**: User privacy is paramount; zero tracking or network phone-home calls.
- **No accounts or cloud sync**: All preferences and timer states remain local via monotonic system clocks and `UserDefaults`.
- **No stopwatch, multi-timer, or pomodoro sprawl**: Cadence is purely a single-session countdown timer.

---

## 2. Prerequisites & Environment

- **Operating System**: macOS 15.0 (Sequoia) or later.
- **Toolchain**: Swift 6.0+ toolchain (Xcode 16.0+ or Apple Command Line Tools).
- **Code Formatter**: `swift-format` (installable via Homebrew or Xcode toolchain).

Check your environment:
```bash
swift --version
swift-format --version
```

---

## 3. Development Workflow

Cadence uses standard Swift Package Manager commands and an included `Makefile`:

### Build & Run
```bash
# Build all package targets (CadenceCore, CadenceUI, CadenceApp)
make build
# or: swift build

# Run the executable directly
swift run CadenceApp
```

### Running Tests
```bash
# Execute unit test suites (76 tests across 10 suites)
make test
# or: swift test
```

### Full Verification Pipeline
Before submitting a pull request, run the full 5-stage verification suite:
```bash
make verify
# or: ./scripts/verify.sh
```
This runs:
1. `swift-format lint --recursive Sources Tests`
2. `swift test` (all unit and component test suites)
3. `swift build` (clean debug build)
4. `./scripts/build-app.sh release` (packaged `.app` bundle assembly)
5. `codesign --verify` (validates ad-hoc application code signature)

---

## 4. Architectural Rules

When contributing code, respect target boundaries:

- **`CadenceCore`**: Pure Swift domain models (`TimerPhase`, `TimerEngineCalculations`), monotonic time abstractions (`TimeSourceProtocol`), and design tokens (`BloodMoonPalette`, `SpacingScale`, `RadiusScale`).
  * Invariant: Never import `SwiftUI`, `AppKit`, or `Combine` into `CadenceCore`.
- **`CadenceUI`**: Presentation layer, SwiftUI components (`CadenceCard`, `ChronoSculptView`), custom controls, and theme bridges. Depends only on `CadenceCore`.
- **`CadenceApp`**: Application executable (`@main`), window lifecycle, `NSApplicationDelegate`, dock reopen logic, and notification routing.

### Swift 6 Concurrency
Cadence compiles with `-strict-concurrency=complete`.
- Ensure all types passed across concurrency boundaries conform to `Sendable`.
- Isolate view models and UI state to `@MainActor`.
- Avoid mutable global state.

### Deterministic Testing
- Never use real-time delays (`Task.sleep`, `Thread.sleep`) in unit tests.
- Use `SimulatedTimeSource` to simulate instant clock advances, pause intervals, and deadline completions deterministically.

---

## 5. Pull Request Guidelines

1. **Keep PRs Focused**: One bug fix or enhancement per PR.
2. **Include Tests**: Add or update unit tests in `Tests/` covering new logic or regressions.
3. **Verify Locally**: Ensure `./scripts/verify.sh` completes with zero warnings and zero test failures.
4. **Clean Commits**: Write clear, descriptive commit messages.
