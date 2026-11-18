# Cadence Project Instructions & Agent Guidelines

## 1. Product Vision & Philosophy

**Cadence** is a precision native macOS countdown timer engineered exclusively with **Swift 6**, **SwiftUI**, and **AppKit**. It is designed to be an atmospheric, tactile utility for deep focus sessions.

- **Native Excellence**: Near-instant cold launch (<40ms), minimal memory footprint (<30 MB idle RAM), and zero external web views or cross-platform runtime layers.
- **Precision Timing**: Monotonic anchor-and-deadline calculations immune to App Nap, thread scheduling delays, and system sleep/wake transitions.
- **Architectural Purity**: Clean separation between headless mathematical domain logic (`CadenceCore`), presentation and design tokens (`CadenceUI`), and system lifecycle/windowing (`CadenceApp`).

---

## 2. Visual Identity: The Blood Moon Design System

All user interface work must adhere strictly to the **Blood Moon** design language:

- **Atmosphere**: Deep, velvety blackish burgundy canvas (`#140A10`), layered surface cards (`#22141F`), and hairline borders (`#3D2232`).
- **Accents**: Restrained crimson accent (`#FF5268`) and highlight (`#FF8595`) reserved exclusively for active timer states, circular ring progress, and primary interactive controls.
- **Typography**: Apple system San Francisco fonts. Prominent hero countdown digits (64pt monospaced bold) using tabular numbers to eliminate layout jitter.
- **Contrast & Accessibility**: Primary text (`#F2E8E8`) guarantees **17.4:1 WCAG AAA** contrast against canvas. All visual motion must support `@Environment(\.accessibilityReduceMotion)`.
- **Authoritative Tokens**: Always reference `BloodMoonPalette`, `SpacingScale`, and `RadiusScale` in `CadenceCore` and their bridges in `CadenceUI`.

---

## 3. Authoritative Roadmap & Current Milestone

The project follows an approved seven-phase roadmap defined in [docs/ROADMAP.md](docs/ROADMAP.md):

1. **Phase 1: Foundation and Environment** — **VERIFIED COMPLETE** (Swift 6 toolchain, modular SPM targets, design tokens, unit tests, verify script).
2. **Phase 2: Visual Design and Interface** — **ACTIVE / CURRENT MILESTONE** (Window shell, countdown display, circular progress ring, primary controls, preset selectors, custom entry).
3. **Phase 3: Timer Engine** — Runtime `TimerStore`, monotonic clock coordination, DisplayLink loop, sleep/wake listeners, App Nap assertions.
4. **Phase 4: Interactions and Persistence** — Wire UI to store, presets, `UserDefaults` state persistence, keyboard shortcuts, audio cues.
5. **Phase 5: Native macOS Integration** — Bundle identity, `.icns` application icon, `UNUserNotificationCenter` completion alerts, window lifecycle.
6. **Phase 6: Polish, Testing, and Bug Fixes** — Full test verification, edge cases, accessibility audit, resource profiling.
7. **Phase 7: GitHub Release and Distribution** — Release builds, packaging, documentation, distribution notes.

> [!IMPORTANT]
> Do not jump ahead into subsequent phases before current milestone acceptance criteria are fully met and verified. Do not duplicate the full roadmap across ad-hoc files; [docs/ROADMAP.md](docs/ROADMAP.md) is the single source of truth.

---

## 4. Architectural Boundaries

Cadence is structured as a decoupled Swift package:

- **`CadenceCore`**: Pure Swift domain models (`TimerPhase`, `TimerEngineCalculations`), monotonic time abstractions (`TimeSourceProtocol`, `ContinuousClock`), design tokens (`BloodMoonPalette`, `SpacingScale`, `RadiusScale`), and mathematical tests. Zero dependencies on SwiftUI or AppKit.
- **`CadenceUI`**: SwiftUI components (`CadenceCard`, progress indicators, countdown displays), color/font extensions, and view previews. Depends only on `CadenceCore`.
- **`CadenceApp`**: Executable macOS app target (`@main`), window management (`WindowGroup`, `NSWindow` configuration), `MenuBarExtra` integration, and application delegate lifecycle.

---

## 5. Engineering Invariants & Safety Rules

Every agent operating in this repository must obey the following invariants:

1. **Inspect Before Modifying**: Always read relevant existing source files, inspect project structure, and check `git status` prior to proposing or applying code changes.
2. **Test Meaningful Changes**: Execute automated unit tests (`swift test`) and formatting/verification checks (`./scripts/verify.sh`) whenever logic or UI components are changed. Never declare a feature complete without running tests.
3. **No Unnecessary Dependencies & No Feature Creep**: Do not add third-party SPM packages, web bridges, or external databases. Stick strictly to P0 requirements for v1.0. Explicitly avoid P2 items (cloud sync, analytics, stopwatch, AI features).
4. **Strict Isolation of Rivet**: The sibling directory `~/Dev/projects/rivet` is strictly off-limits. Never read, edit, reference, or run commands touching Rivet.
5. **No Automatic Commits, Pushes, or Releases**: Do not run `git commit`, `git push`, `git tag`, or release scripts without explicit user request. The engineer retains full manual custody of Git history.
6. **No Destructive Operations**: Never execute `git reset --hard`, `git clean -f`, `git restore .`, `git checkout -- .`, or branch deletions.
7. **Milestone Handoff Report**: At the conclusion of any milestone or significant task, generate a structured handoff report detailing completed work, verified test results, and next actions.
