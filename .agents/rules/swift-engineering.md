---
description: Maintain Swift 6 strict concurrency, architectural boundaries, and pure testable logic.
trigger: always_on
---

# Rule: Swift Engineering Conventions

1. **Swift 6 Strict Concurrency**: Adhere to Swift 6 complete concurrency checking (`-strict-concurrency=complete`). Respect `@MainActor` isolation on UI types, use `Sendable` types across actor boundaries, and avoid shared mutable global state.
2. **Preserve Target Boundaries**:
   - `CadenceCore`: Pure domain models, mathematical calculations, and design tokens. Never import `SwiftUI`, `AppKit`, or `Combine` into `CadenceCore`.
   - `CadenceUI`: Presentation layer, SwiftUI components, and theme extensions. Depends on `CadenceCore`.
   - `CadenceApp`: Application entry point, window styling, and system integration.
3. **Pure & Testable Timekeeping**:
   - Mathematical calculations must remain decoupled from display refresh loops.
   - Time calculations must use monotonic anchors (`ContinuousClock`, `TimeSourceProtocol`) rather than Wall Clock intervals or integer tick counters.
4. **Code Quality**: Ensure all code compiles cleanly without warnings and adheres to `.swift-format` specifications (`swift-format lint --recursive Sources Tests`).
