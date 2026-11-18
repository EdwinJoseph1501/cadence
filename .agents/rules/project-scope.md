---
description: Restrict development strictly to the approved Cadence v1.0 roadmap scope and prevent feature creep.
trigger: always_on
---

# Rule: Project Scope & Feature Boundaries

1. **Approved Roadmap Only**: Work must align directly with the active milestone in `docs/ROADMAP.md`. The current active phase is **Phase 2: Visual Design and Interface**.
2. **Zero Unnecessary Infrastructure**: Do not introduce complex frameworks, reactive frameworks outside SwiftUI, third-party databases, or cross-platform shims.
3. **Explicitly Out of Scope for v1.0**:
   - No stopwatch or multi-timer modes.
   - No user accounts, cloud sync, or remote APIs.
   - No telemetry, analytics, or session logging databases.
   - No external productivity integrations (calendars, webhooks).
   - No AI assistant features or complex plugin architectures.
4. **Minimal External Dependencies**: Maintain Cadence as a self-contained Swift package utilizing only Apple's native frameworks (`SwiftUI`, `AppKit`, `UserNotifications`).
