---
name: timer-engine
description: Use this skill when designing, implementing, modifying, or testing Cadence's countdown calculations, monotonic clocks, timer state machines, sleep/wake recovery, and persistence.
---

# Timer Engine Engineering for Cadence

## Purpose
Ensure drift-free, deterministic, and testable countdown timekeeping that remains accurate across App Nap, system sleep/wake events, backgrounding, and application relaunch.

## When to Use
- Working on domain logic in `Sources/CadenceCore/` or runtime coordination in `Sources/CadenceUI/`.
- Implementing or modifying state transitions (`idle`, `running`, `paused`, `completed`).
- Configuring sleep/wake recovery via `NSWorkspace.didWakeNotification`.
- Adding or running deterministic timer unit tests with `SimulatedTimeSource`.

## Practical Workflow
1. **Mathematical Foundations (`CadenceCore`)**:
   - Calculate remaining time strictly from monotonic anchor points:
     `remaining = max(0, targetDeadline - currentTime)`.
   - Never use integer decrementing counters (`remaining -= 1`).
   - Keep calculations pure and stateless in `TimerEngineCalculations`.
2. **Clock Abstraction**:
   - Rely on `TimeSourceProtocol` (`ContinuousClockTimeSource` in production, `SimulatedTimeSource` in tests).
   - Monotonic continuous time continues counting even while macOS is sleeping.
3. **State Machine Transitions**:
   - `idle`: Target duration selected; progress = 0.0.
   - `running`: Anchor timestamp set; deadline computed.
   - `paused`: Remaining duration preserved; anchor cleared.
   - `completed`: Reached when deadline <= now; single-fire completion trigger.
4. **Sleep/Wake & App Nap Handling**:
   - On wake (`NSWorkspace.didWakeNotification`), re-evaluate current time against deadline immediately.
   - Use `ProcessInfo.processInfo.beginActivity(options: .userInitiated, ...)` during active countdowns to prevent throttling.
5. **Persistence**:
   - Store selected duration and active state in `UserDefaults`.
   - On restart, evaluate elapsed time without resetting or restarting the countdown.

## Project Constraints
- `CadenceCore` must have zero external dependencies and zero UI imports.
- Pure calculations must be 100% covered by deterministic unit tests.

## Verification Expectations
- Run `swift test --filter TimerModelTests`.
- All tests must complete deterministically in < 0.05s without asynchronous sleep calls.

## Common Mistakes to Avoid
- **Wall Clock Reliance**: Using `Date()` or system time is vulnerable to NTP clock adjustments and daylight saving shifts. Always use monotonic time.
- **Timer Drift from UI Frame Rate**: Coupling countdown calculations to `TimelineView` or `Timer.publish` causes accumulated drift when frames drop.
- **Double Completion Events**: Failing to guard completion triggers, causing duplicate notifications or sounds.
