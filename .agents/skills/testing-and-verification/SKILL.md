---
name: testing-and-verification
description: Use this skill when running tests, formatting checks, build verification, regression checks, and generating honest verification reports for Cadence.
---

# Testing & Verification for Cadence

## Purpose
Enforce rigorous, automated verification across all layers of Cadence, ensuring zero regressions, accurate reporting, clean style compliance, and reproducible quality.

## When to Use
- Validating any code changes before submitting them for review or finishing a task.
- Adding unit tests for new domain features, timer states, or UI bridges in `Tests/`.
- Checking code style with `swift-format`.
- Running the master verification script (`./scripts/verify.sh`).

## Practical Workflow
1. **Formatting & Style Verification**:
   - Check lint: `swift-format lint --recursive Sources Tests`
   - Auto-format if needed: `swift-format format --in-place --recursive Sources Tests`
2. **Automated Unit Tests**:
   - Execute test suites: `swift test`
   - Run specific test suite: `swift test --filter CadenceCoreTests`
   - Check test execution time: unit tests should complete in < 0.1s.
3. **Debug & Release Compilation**:
   - Debug: `swift build`
   - Release: `swift build -c release`
4. **Full Verification Pipeline**:
   - Run `./scripts/verify.sh`
   - Verifies 5 gates:
     1. `swift-format` style check.
     2. Automated unit tests across all targets.
     3. Debug compilation.
     4. Release `.app` bundle assembly (`scripts/build-app.sh release`).
     5. Ad-hoc codesign verification (`codesign -v build/Cadence.app`).
5. **Honest Reporting**:
   - Record exact test counts, execution durations, and exit codes.
   - Never suppress compiler warnings or failing assertions.

## Project Constraints
- Swift Testing library (`import Testing`, `@Test`, `@Suite`) is the standard testing framework.
- Unit tests must be 100% deterministic with zero external network or disk dependencies.

## Verification Expectations
- All 5 steps of `./scripts/verify.sh` must report `PASSED`.
- Zero compiler errors or warnings (disregard harmless non-fatal CommandLineTools search path notice).

## Common Mistakes to Avoid
- **Claiming Tests Passed Without Running Them**: Always execute the actual command and inspect the stdout/stderr.
- **Using Sleep in Tests**: Flaky tests arise from `sleep(1)`. Always use `SimulatedTimeSource.advance(by:)`.
- **Modifying Test Tolerances to Mask Bugs**: Never widen mathematical tolerances to make a failing calculation test pass. Fix the calculation.
