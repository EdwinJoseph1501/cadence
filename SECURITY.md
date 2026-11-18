# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

---

## Security Model & Surface

Cadence is engineered with a minimal security attack surface:
- Zero external dependencies.
- Zero network requests, phone-home telemetry, or cloud synchronization.
- Sandboxed or standalone local macOS desktop execution.
- System notifications are scheduled purely locally via `UNUserNotificationCenter`.

---

## Reporting a Vulnerability

If you discover a security vulnerability in Cadence, please do not open a public GitHub issue.

Instead, please report security-sensitive findings responsibly by contacting the project maintainers via GitHub Private Vulnerability Reporting or via email.

Please include:
1. Description of the vulnerability.
2. Steps to reproduce or proof-of-concept.
3. Potential impact.

We will acknowledge receipt within 48 hours and work with you on a resolution before any public disclosure.
