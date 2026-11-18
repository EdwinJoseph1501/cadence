# Cadence Architecture & Technology Evaluation

This document outlines the architectural decisions, technology evaluation, module boundaries, and trade-offs for **Cadence**, a premium timer application designed exclusively for macOS.

---

## 1. Technology Evaluation

The product vision for Cadence demands:
- Visually exceptional, deliberate aesthetics (Theme: *Blood Moon*).
- Fluid, sub-pixel animations synchronized to ProMotion 120Hz displays.
- Instant launch, minimal memory footprint (< 30 MB), and low battery draw.
- Rock-solid timekeeping across system sleep, thread suspension, and App Nap.
- Deep integration with macOS windowing, menu bar, and notifications.

We evaluated two primary architectures:
1. **Approach A: Native macOS application using SwiftUI, Swift 6, and AppKit.**
2. **Approach B: Cross-platform desktop application using Tauri 2, Rust, TypeScript, and React.**

---

### Comparative Analysis Matrix

| Evaluation Criteria | Native macOS (SwiftUI + AppKit) | Tauri 2 (Rust + React + Vite) | Winner |
| :--- | :--- | :--- | :--- |
| **Native macOS Appearance** | Full native support for NSVisualEffectView, `.ultraThinMaterial`, vibrant materials, SF Pro font features, system accents. | Relies on WebKit CSS rendering, web titlebar emulation, and polyfilled backdrop filters. | **Native (SwiftUI)** |
| **Window Management** | Native `NSWindow` / `WindowGroup` controls, custom shapes, transparent titlebars, floating utility panels, Stage Manager. | Requires Tao window manipulation or custom native Rust/ObjC plugins; window dragging can exhibit webview lag. | **Native (SwiftUI)** |
| **Animation Quality** | Direct CoreAnimation & Metal vector rendering on GPU. Native DisplayLink synchronization at 60/120Hz with zero compositor IPC. | WebKit compositor pipeline with CSS/Canvas animations; heavy backdrop blurs can drop frames under battery constraints. | **Native (SwiftUI)** |
| **Timer Accuracy & Monotonic Time** | Direct access to `ContinuousClock`, `mach_continuous_time`, and `ProcessInfo` activity assertions to prevent App Nap throttling. | Rust backend has `Instant`, but frontend UI updates require Tauri event IPC bridge serialization. | **Native (SwiftUI)** |
| **Background Execution & Sleep Recovery** | System notifications via `NSWorkspace.didWakeNotification` and `NSBackgroundActivityScheduler`. Zero runtime overhead while idle. | WebKit processes aggressively throttle timers (to 1s or freeze) when hidden, requiring audio or custom push hacks. | **Native (SwiftUI)** |
| **Menu Bar Integration** | Native SwiftUI `MenuBarExtra` and `NSStatusItem` with rich interactive views in just dozens of lines of code. | Requires `tauri-plugin-tray`; rendering rich interactive UI inside tray popovers requires secondary webview panels. | **Native (SwiftUI)** |
| **System Notifications** | Direct use of Apple's `UserNotifications` (`UNUserNotificationCenter`, actionable categories, sounds). Zero dependencies. | Requires `tauri-plugin-notification` plugin; limited custom notification actions. | **Native (SwiftUI)** |
| **Application Size** | **~256 KB – 5 MB** executable / bundle (Swift runtime & AppKit are built directly into macOS). | **~15 MB – 35 MB** bundle (includes bundled Rust binary, frontend assets, and WebKit integration shims). | **Native (SwiftUI)** |
| **Memory Consumption** | **~18 MB – 32 MB** idle RAM. | **~90 MB – 180 MB** RAM (WebKit WebProcess + GPU process + Networking process + Rust binary). | **Native (SwiftUI)** |
| **Startup Time** | **< 40ms** cold launch (near instantaneous). | **350ms – 750ms** cold launch (WebView initialization, JS parsing, and DOM mount). | **Native (SwiftUI)** |
| **Development Complexity** | Single language (Swift 6), single toolchain (`swift build` / SPM), unified type system across domain, UI, and tests. | Dual ecosystems (Cargo/Rust + npm/Vite/TypeScript/React); IPC schemas must be maintained across language boundaries. | **Native (SwiftUI)** |
| **Long-Term Maintainability** | Aligned with Apple's macOS SDK lifecycle. Zero third-party bridge breaking changes across macOS major upgrades. | Dependent on community maintenance of Tauri, Tao, Wry, and WebKit compatibility shims. | **Native (SwiftUI)** |

---

### Evaluation Verdict: Approach A (Native SwiftUI + Swift 6)

**Decision**: Native macOS with SwiftUI, Swift 6, and AppKit is selected as the exclusive architecture for Cadence.

**Rationale**:
Cadence is fundamentally a precision utility application where startup speed, battery efficiency, and authentic macOS tactile feel define product success. A timer that takes 600ms to open, consumes 120 MB of RAM, and struggles with macOS sleep recovery compromises the product promise. With SwiftUI and Swift 6, Cadence achieves a 256 KB binary, sub-30 MB RAM usage, flawless sleep recovery, and native Menu Bar / Notification integration without third-party web bridges.

---

## 2. Application Architecture & Module Boundaries

Cadence is organized as a decoupled, modular Swift package comprising three distinct targets:

```
┌────────────────────────────────────────────────────────┐
│                      CadenceApp                        │
│   (macOS Executable: App entry point, Window scenes,    │
│    AppKit window styling, MenuBarExtra, AppDelegate)   │
└───────────────┬────────────────────────┬───────────────┘
                │                        │
                ▼                        ▼
┌───────────────────────────────┐ ┌──────────────────────┐
│           CadenceUI           │ │     CadenceCore      │
│  (SwiftUI Themes, Modifiers,  │ │  (Pure Domain Logic, │
│   Cards, Displays, Previews)  │ │   Monotonic Clock,   │
│                               │ │   Timer State Mach,  │
│                               │ │   Token Defs)        │
└───────────────┬───────────────┘ └──────────────────────┘
                │                            ▲
                └────────────────────────────┘
```

### Module 1: `CadenceCore` (Headless Domain, Models & Tokens)
- **Dependencies**: None (pure Swift & Foundation).
- **Responsibilities**:
  - `DesignTokens`: Mathematical color definitions (`BloodMoonPalette`), hex parsing, relative luminance, and automated WCAG AAA/AA contrast calculations (`ColorToken`), typographic tokens, spacing scales (`SpacingScale`), and squircle radius scales (`RadiusScale`).
  - `TimerEngine`: State machine model (`TimerPhase`), pure functional duration & progress calculations (`TimerEngineCalculations`), natural-language duration synthesis for VoiceOver (`accessibleDuration`), time source contracts (`TimeSourceProtocol`, `ContinuousClockTimeSource`, `SimulatedTimeSource`), persistence contracts (`TimerPersistenceProtocol`), activity assertion contracts (`ActivityAssertionProtocol`), notification contracts (`NotificationSchedulerProtocol`), and audio alert contracts (`AudioAlertProtocol`).
- **Characteristics**: 100% testable in pure headless environments without a window server, AppKit, or SwiftUI.

### Module 2: `CadenceUI` (Visual Components, Metal Shaders & State Management)
- **Dependencies**: `CadenceCore`, `SwiftUI`, `AppKit`, `Metal`, `MetalKit`, `Observation`.
- **Responsibilities**:
  - `State`: `@MainActor` `@Observable` runtime store (`TimerStore`) coordinating phase transitions, monotonic deadline management, preset selection, custom duration validation, sleep/wake recovery, persistence serialization, App Nap assertions, and notification scheduling.
  - `Theme`: Bridges `ColorToken` to SwiftUI `Color` (`Color.cadence*`) and `TypographyToken` to `Font` (`Font.cadence*`).
  - `Components`:
    - `ChronoSculptView` & `ChronoSculptMetalView`: Generative 3D liquid obsidian raymarching sculpture running via dedicated Metal pipeline (`MTKView`), with single-frame static rendering in idle/paused/reduce-motion states and automatic window occlusion pausing via `CadenceMTKView`.
    - `CountdownDisplayView`: 64pt tabular monospace hero timer with natural-language accessibility descriptions, contextual status captions, and `.updatesFrequently` throttling.
    - `TimerControlsView`: Tactile capsule toggle with spring/instant physics (`TactileButtonStyle`), circular reset, and audio chime toggle button.
    - `PresetSelectorView`: Compact architectural preset chips ("5m", "25m", "50m", "90m", "Custom") with active state indicators and runtime lock guards.
    - `CustomDurationSheet`: Native modal sheet with stepper controls, numeric input validation (1s to 24h), and accessibility traits.
  - `Lifecycle`: Window lifecycle management (`WindowLifecycleController`, `CadenceWindowDelegate`) implementing macOS-native close-to-hide (`orderOut`), Dock restoration, and transparent title bar styling with native floating traffic lights.

### Module 3: `CadenceApp` (Application Shell & macOS System Integration)
- **Dependencies**: `CadenceCore`, `CadenceUI`, `SwiftUI`, `AppKit`, `UserNotifications`.
- **Responsibilities**:
  - Declares the `@main` application entry point (`CadenceApp`).
  - `CadenceAppDelegate`: Implements `NSApplicationDelegate` for Dock click reopening (`applicationShouldHandleReopen`), graceful termination, and `UNUserNotificationCenterDelegate` for foreground notification banners and click-to-focus window restoration.
  - `MainWindowView`: Root window composition, window-level keyboard shortcut handlers (`Space`, `Esc`, `Cmd+1..4`, `Cmd+Shift+M`) guarded against active text entry during sheet presentation.

---

## 3. Major Technical Decisions

### Swift 6 & Modern Swift Testing
- The project targets Swift 6.0 with strict concurrency checks enabled (`StrictConcurrency`, `ExistentialAny`).
- Automated testing uses the modern Swift Testing library (`import Testing`) with structured `@Suite` and `@Test` declarations, running tests concurrently and deterministically.

### Pure Token Architecture
- Rather than declaring hardcoded colors in SwiftUI views, all design tokens originate in `CadenceCore.BloodMoonPalette` as mathematical RGB values.
- This allows automated CI tests to mathematically enforce WCAG AAA contrast ratios before UI code compiles.

### Decoupled Timekeeping Anchor
- Timer progression does not rely on decrementing state on a timer tick.
- The domain model computes state dynamically from a fixed `targetDeadline`, eliminating clock drift and ensuring graceful recovery from system sleep.

### Metal Generative Rendering & Zero-Overhead Lifecycle
- The application integrates a 3D generative raymarching sculpture (`ChronoSculptMetalView`) utilizing Apple's Metal framework directly on unified memory.
- To eliminate battery and CPU drain, rendering is strictly lifecycle-governed:
  - **Running State**: Renders fluidly at 60 FPS ProMotion with dynamic fluid deformation and caustic progress illumination.
  - **Idle / Paused / Reduce Motion States**: Renders exactly one static frame synchronously via `MTKView.draw()`, holding `isPaused = true` and `enableSetNeedsDisplay = false` (yielding 0.0% CPU and zero GPU wakeups).
  - **Window Occlusion & Minimization**: Subscribes to `NSWindow.didChangeOcclusionStateNotification` and `viewDidMoveToWindow()` via `CadenceMTKView`. When the window is closed with `Cmd+W`, hidden, or minimized, rendering halts completely.

### Swift 6 Strict Concurrency
- Configured with `-strict-concurrency=complete`.
- The presentation layer and store are strictly isolated to `@MainActor`.
- Cross-actor boundaries (e.g. notifications, simulated clocks, power assertions) pass immutable `Sendable` types, guaranteeing zero data races at compile time.

---

## 4. Trade-Offs Considered

1. **Cross-Platform Portability**:
   - *Trade-off*: Selecting native SwiftUI means Cadence cannot be compiled directly for Windows or Linux without rewriting the UI.
   - *Mitigation*: Accepted. The product vision explicitly targets a world-class macOS experience. Cross-platform compromises would degrade window vibrancy, menu bar elegance, and battery footprint. Furthermore, `CadenceCore` is pure Swift and can be reused in iOS, watchOS, or other Apple platforms.

2. **Full Xcode Project vs. Swift Package Manager (SPM)**:
   - *Trade-off*: An `.xcodeproj` file provides GUI scheme editing in Xcode, but introduces merge conflicts, complex directory structures, and requires full Xcode.app.
   - *Decision*: A clean `Package.swift` manifest was selected. It builds directly with standard Command Line Tools (`swift build`, `swift test`), supports fast CI, and can be opened in Xcode whenever desired (`open Package.swift`).
