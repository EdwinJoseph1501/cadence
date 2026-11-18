---
description: Require automated test coverage and honest reporting for all meaningful code changes.
trigger: always_on
---

# Rule: Testing & Verification Policy

1. **Verify Meaningful Changes**: Any change to calculations, domain state, token bridges, or view logic must be accompanied or validated by tests in `Tests/`.
2. **Standard Verification Pipeline**:
   - Run `swift test` for unit tests.
   - Run `swift-format lint --recursive Sources Tests` for formatting.
   - Run `./scripts/verify.sh` to validate the full 5-step suite (lint, unit tests, debug build, release bundle, codesign).
3. **Deterministic Testing**:
   - Never use real-time delays (`sleep`, `Task.sleep`) in unit tests.
   - Inject `SimulatedTimeSource` to simulate instant clock advances, pause intervals, and deadline completions deterministically.
4. **Honest Reporting**:
   - Distinguish verified test executions from unverified assumptions.
   - Report test failures immediately with exact error messages and reproduction steps.
   - Never silence or bypass failing tests or linter warnings.
