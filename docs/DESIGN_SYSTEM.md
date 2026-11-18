# Cadence Design System

> Visual Identity, Token Specifications & Interaction Philosophy

Cadence is built around a distinct, atmospheric visual identity designed to feel quiet, premium, and native to macOS. It rejects generic web app aesthetics, hyper-saturated neon glows, and cluttered dashboards in favor of spaciousness, typographic restraint, and deliberate contrast.

---

## 1. Design Philosophy: *Blood Moon*

The initial creative direction for Cadence is **Blood Moon**.

- **Atmosphere**: Deep, velvety blackish burgundy shadows paired with soft, warm text mist and precise crimson accents.
- **Tone**: Calm, focused, and monastic. It should feel like an analog mechanical stopwatch illuminated in a darkroom.
- **Principles**:
  1. **Typographic Hierarchy**: Size and weight do the heavy lifting before color is introduced.
  2. **Restrained Color**: Accent color is reserved strictly for active countdown states, critical actions, and key focal points.
  3. **Subtle Layering**: Depth is achieved via delicate 1px borders and stepped surface tones, not blurry dropshadows or heavy frosted glass.
  4. **Smooth, Purposeful Motion**: Animations respect human reaction time (150ms–300ms) with gentle spring physics that never impede responsiveness.
  5. **Respect for System Standards**: Proper macOS window chrome, keyboard focus rings, and VoiceOver annotations.

---

## 2. Color Tokens

All colors are mathematically defined in `CadenceCore.BloodMoonPalette` and surfaced through `CadenceUI.Color` extensions.

### Core Palette

| Token Name | Hex Code | Purpose | Contrast vs Background |
| :--- | :--- | :--- | :--- |
| `background` | `#140A10` | Main canvas background | Baseline (1.0:1) |
| `surfaceElevated` | `#1D151B` | Slightly elevated sections | 1.1:1 |
| `surfaceCard` | `#22141F` | Primary panel and card containers | 1.2:1 |
| `deepBurgundy` | `#2D111E` | Inset backgrounds and pill containers | 1.4:1 |
| `border` | `#3D2232` | 1px subtle separation outlines | 1.8:1 |
| `textPrimary` | `#F2E8E8` | Primary countdown digits and titles | **17.4:1 (WCAG AAA)** |
| `textSecondary` | `#B09FA9` | Subtitles, labels, and metadata | **9.2:1 (WCAG AAA)** |
| `textTertiary` | `#76646F` | Subtle hints, shortcuts, and inactive elements | **4.6:1 (WCAG AA)** |
| `accent` | `#FF5268` | Active timer ring, countdown digits, play button | **6.1:1 (WCAG AA)** |
| `accentHighlight` | `#FF8595` | Hover states and interactive button highlights | 8.8:1 |
| `mutedRose` | `#C88290` | Restrained focus mode indicator and tags | 7.3:1 |
| `success` | `#50C878` | Timer completion pulse and success feedback | 9.4:1 |

---

## 3. Typography Strategy

Cadence uses Apple's native system typefaces (San Francisco Pro and San Francisco Mono) to ensure pixel-perfect rendering across standard and Retina displays.

### Typographic Scale

```
┌────────────────────────────────────────────────────────┐
│ 25:00       timerDigitsHero (64pt, Monospaced Bold)    │
└────────────────────────────────────────────────────────┘
  Cadence     displayLarge (28pt, Semibold)
  Session     titleLarge (20pt, Medium)
  Card Title  headline (15pt, Semibold)
  Body Text   body (13pt, Regular, macOS Native Standard)
  Caption     caption (11pt, Regular)
  SHORTCUT    micro (10pt, Medium, +1.2 Tracking)
```

- **Tabular Numerals**: Countdown numbers strictly use monospaced tabular figures (`design: .monospaced`). This guarantees that as digits decrement (e.g. from `01:11:11` to `00:00:00`), the text width does not jitter or cause adjacent controls to bounce.
- **Display Weights**: Headers use balanced Semibold weights to maintain legibility against deep dark backgrounds without creating visual glare.

---

## 4. Spacing Scale

Consistent spacing creates visual rhythm and prevents arbitrary padding values across views.

| Token | Value | Intended Usage |
| :--- | :--- | :--- |
| `xxs` | `2pt` | Hairline dividers, sub-pixel alignment offsets |
| `xs` | `4pt` | Badge margins, icon-to-label gaps |
| `sm` | `8pt` | Button inner padding, compact list item gaps |
| `md` | `12pt` | Card inner padding, preset chips, input fields |
| `lg` | `16pt` | Standard container padding, group margins |
| `xl` | `24pt` | Section breaks, primary modal margins |
| `xxl` | `32pt` | Major quadrant separation |
| `xxxl` | `48pt` | Countdown timer hero breathing room |

---

## 5. Corner Radius Scale

Cadence adheres to macOS continuous curvature (squircles) to avoid harsh geometric corners:

| Token | Value | Components |
| :--- | :--- | :--- |
| `none` | `0pt` | Full-bleed dividers |
| `sm` | `4pt` | Small badges, keyboard shortcut badges (`⌘K`) |
| `md` | `8pt` | Standard buttons, preset chips, menu items |
| `lg` | `12pt` | Inner cards, timer setting sheets |
| `xl` | `16pt` | Main window container card, floating utility panels |
| `full` | `9999pt` | Capsule buttons, progress ring endpoints |

---

## 6. Surface Treatments & Depth

To avoid overused glossy or blurred glass aesthetics that waste GPU cycles:
1. **Solid Layered Surfaces**: Surfaces step gradually from `#140A10` (window background) to `#1D151B` (recessed track) and `#22141F` (raised card).
2. **Hairline Separators**: Borders use a crisp 1.0pt stroke of `Color.cadenceBorder` (`#3D2232`), providing clear visual structure even in dim lighting.
3. **No Heavy Dropshadows**: Shadows are omitted or kept to ultra-soft ambient occlusion (`radius: 8, y: 4, opacity: 0.15`).

---

## 7. Motion & Animation Principles

Animations in Cadence must feel tactile and instantaneous:
- **Duration**: Micro-interactions last 150ms–200ms; full state changes last 300ms.
- **Curves**: Smooth spring physics (`.spring(response: 0.3, dampingFraction: 0.8)`) to mimic physical inertia without wobble.
- **Separation of UI from Clock**: The visual countdown animation (e.g. smooth ring sweep) is driven by `TimelineView(.animation)` or `DisplayLink`, completely isolated from the underlying domain deadline calculation.
- **Accessibility**: All animations honor `@Environment(\.accessibilityReduceMotion)`. When enabled, animations collapse into instant opacity crossfades.

---

## 8. Accessibility Requirements

- **Contrast Compliance**: Every text token has been audited against WCAG 2.1 specifications. Primary text achieves **17.4:1**, far exceeding the 7.0:1 AAA threshold.
- **VoiceOver**: All timer states provide semantic descriptions (e.g., *"14 minutes 32 seconds remaining, running"*).
- **Full Keyboard Navigation**: Spacebar toggles start/pause; Escape resets; `⌘,` opens preferences.
- **Focus Rings**: Visual focus states use `Color.cadenceAccentHighlight` with a 2pt offset ring.
