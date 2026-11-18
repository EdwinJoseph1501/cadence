---
name: swiftui-development
description: Use this skill when developing, refactoring, or reviewing native macOS SwiftUI components, views, layouts, state management, and Swift concurrency in Cadence.
---

# SwiftUI Development for Cadence

## Purpose
Guide the construction and composition of native macOS SwiftUI interfaces conforming to Swift 6 strict concurrency, AppKit window standards, and Cadence's decoupled architecture.

## When to Use
- Implementing or modifying views in `Sources/CadenceUI/` or `Sources/CadenceApp/`.
- Integrating state bindings between the UI and runtime stores (`@State`, `@Observable`, `@Binding`).
- Ensuring thread safety with `@MainActor` and Swift 6 concurrency.
- Managing macOS window scenes, sheets, or popovers.

## Practical Workflow
1. **Target Selection**:
   - Place reusable UI components and previews in `Sources/CadenceUI/`.
   - Place window scenes, app delegates, and top-level commands in `Sources/CadenceApp/`.
2. **Component Composition**:
   - Compose views out of small, single-responsibility views.
   - Use `CadenceCard` as the container for elevated surfaces.
   - Leverage `Color.cadence*` and `Font.cadence*` token extensions.
3. **State Management**:
   - Use Swift 6 `@Observable` classes or `@State` structs.
   - Mark UI-bound stores and view logic with `@MainActor`.
   - Keep side effects out of view bodies (`body` must remain pure).
4. **Layout & Windowing**:
   - Constrain window frame dimensions sensibly (e.g. 420x520 default with minimum width/height).
   - Use AppKit integration bridges (`NSWindowDelegate`, `NSViewRepresentable`) only when native SwiftUI lacks window-level control.

## Project Constraints
- Must compile under Swift 6 strict concurrency (`-strict-concurrency=complete`).
- Zero third-party view libraries or web wrappers.
- `CadenceCore` must never import `SwiftUI` or `AppKit`.

## Verification Expectations
- Run `swift build` and confirm zero concurrency or type warnings.
- Run `swift-format lint --recursive Sources Tests` to verify formatting.
- Verify view previews or components run locally without frame drops or layout jitter.

## Common Mistakes to Avoid
- **Driving Timer from View State**: Never use `@State` timer tick counters in views. The view must observe elapsed calculations from the underlying time source.
- **Ignoring Tabular Numbers**: Using proportional fonts for countdown digits causes visual layout jumping every second. Always use tabular numbers.
- **Breaking Concurrency Boundaries**: Accessing UI properties from background threads without `@MainActor`.
