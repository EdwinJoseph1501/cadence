---
description: Enforce Blood Moon design tokens, typographic hierarchy, and accessibility standards.
trigger: always_on
---

# Rule: Blood Moon Design System Consistency

1. **Token Authority**: Use established tokens from `BloodMoonPalette`, `SpacingScale`, and `RadiusScale` via `Color.cadence*` and `Font.cadence*` extensions. Do not hardcode arbitrary hex codes or magic dimension numbers in views.
2. **Typographic Discipline**:
   - Hero countdown digits must use tabular monospaced numbers (`TypographyScale.timerDigitsHero`) to prevent character width jitter.
   - Text hierarchy must follow established scales: `displayLarge` (28pt), `titleLarge` (20pt), `headline` (15pt), `body` (13pt), `caption` (11pt).
3. **Contrast Compliance**:
   - Ensure primary text meets WCAG AAA standards (minimum 7:1; current design achieves 17.4:1).
   - Ensure secondary text meets WCAG AA standards (minimum 4.5:1; current achieves 9.2:1).
4. **Motion & Accessibility**:
   - All animated elements (countdown rings, transitions, pulsing completion states) must inspect `@Environment(\.accessibilityReduceMotion)` and provide immediate, non-animated state changes when reduced motion is preferred.
   - Provide clear accessibility labels and traits for all interactive controls (buttons, preset chips, custom inputs).
