---
name: macos-design-system
description: Use this skill when applying, reviewing, or extending the Blood Moon design system tokens, typography, circular progress ring, spacing, colors, and accessibility features in Cadence.
---

# macOS Design System (Blood Moon) for Cadence

## Purpose
Maintain aesthetic cohesion, visual restraint, WCAG contrast compliance, and macOS platform standards across all Cadence visual components.

## When to Use
- Styling views, buttons, countdown displays, and modal sheets.
- Creating or tweaking the circular progress ring indicator.
- Checking contrast ratios and font sizing.
- Implementing reduced motion behaviors for macOS accessibility.

## Practical Workflow
1. **Palette Application**:
   - Canvas Background: `Color.cadenceBackground` (`#140A10`).
   - Cards / Containers: `Color.cadenceSurfaceCard` (`#22141F`) with 1px `Color.cadenceBorder` (`#3D2232`).
   - Accent & Active Ring: `Color.cadenceAccent` (`#FF5268`).
   - Interactive Hover: `Color.cadenceAccentHighlight` (`#FF8595`).
   - Completion Flash: `Color.cadenceSuccess` (`#50C878`).
2. **Typography Hierarchy**:
   - Hero Digits: `Font.cadenceTimerDigitsHero` (64pt monospaced bold, tabular figures).
   - Display: `Font.cadenceDisplayLarge` (28pt semibold).
   - Headings: `Font.cadenceTitleLarge` (20pt medium), `Font.cadenceHeadline` (15pt semibold).
   - Body & Hints: `Font.cadenceBody` (13pt regular), `Font.cadenceCaption` (11pt medium).
3. **Circular Progress Indicator**:
   - Background Track: Circular stroke with `Color.cadenceBorder` or `Color.cadenceDeepBurgundy`.
   - Active Sweep: Trimmed stroke from 0.0 to progress fraction with `Color.cadenceAccent`.
   - Distinct States: Idle (full accent track or subtle border), Running (animated progress sweep), Paused (accent with reduced opacity or distinct tint), Completed (success accent pulse).
4. **Accessibility & Reduced Motion**:
   - Detect `@Environment(\.accessibilityReduceMotion) var reduceMotion`.
   - If `reduceMotion` is active, disable spring animations and progress ring interpolation; snap states instantly.
   - Ensure all interactive elements include `.accessibilityLabel(...)` and appropriate `.accessibilityValue(...)`.

## Project Constraints
- Strict adherence to defined tokens in `CadenceCore.BloodMoonPalette`.
- All text must meet or exceed WCAG AA (minimum 4.5:1), with primary text meeting WCAG AAA (17.4:1).

## Verification Expectations
- Run `swift test --filter DesignTokenTests` to verify contrast ratios, spacing progression, and radius hierarchy.
- Visually verify darkroom aesthetic in both dark and light macOS appearance settings (Cadence remains atmospheric darkroom).

## Common Mistakes to Avoid
- **Hardcoding Hex Colors**: Placing raw hex strings in views instead of referencing `Color.cadence*`.
- **Blurry Drop Shadows**: Using heavy Gaussian blurs instead of clean, layered surface cards with subtle 1px border strokes.
- **Ignoring Reduced Motion**: Using non-optional long spring animations for users requesting reduced motion.
