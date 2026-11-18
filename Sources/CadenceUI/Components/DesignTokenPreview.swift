import CadenceCore
import SwiftUI

/// Visual demonstration component displaying the Blood Moon color palette,
/// typography hierarchy, and contrast ratios.
public struct DesignTokenPreview: View {
    public init() {}

    private let swatches: [(name: String, hex: String, color: Color, token: ColorToken)] = [
        ("Background", "#140A10", .cadenceBackground, BloodMoonPalette.background),
        ("Elevated Surface", "#1D151B", .cadenceSurfaceElevated, BloodMoonPalette.surfaceElevated),
        ("Card Surface", "#22141F", .cadenceSurfaceCard, BloodMoonPalette.surfaceCard),
        ("Deep Burgundy", "#2D111E", .cadenceDeepBurgundy, BloodMoonPalette.deepBurgundy),
        ("Border", "#3D2232", .cadenceBorder, BloodMoonPalette.border),
        ("Accent Crimson", "#FF5268", .cadenceAccent, BloodMoonPalette.accent),
        ("Warm Highlight", "#FF8595", .cadenceAccentHighlight, BloodMoonPalette.accentHighlight),
        ("Muted Rose", "#C88290", .cadenceMutedRose, BloodMoonPalette.mutedRose),
        ("Primary Text", "#F2E8E8", .cadenceTextPrimary, BloodMoonPalette.textPrimary),
        ("Secondary Text", "#B09FA9", .cadenceTextSecondary, BloodMoonPalette.textSecondary),
        ("Tertiary Text", "#76646F", .cadenceTextTertiary, BloodMoonPalette.textTertiary),
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingScale.xl) {
            // Header
            VStack(alignment: .leading, spacing: SpacingScale.xs) {
                Text("CADENCE")
                    .font(.cadenceDisplay)
                    .foregroundStyle(Color.cadenceTextPrimary)

                Text("Design System & Architectural Token Foundation — Theme: Blood Moon")
                    .font(.cadenceHeadline)
                    .foregroundStyle(Color.cadenceTextSecondary)
            }

            // Typography Showcase
            CadenceCard {
                VStack(alignment: .leading, spacing: SpacingScale.md) {
                    Text("TYPOGRAPHY HIERARCHY")
                        .font(.cadenceMicro)
                        .foregroundStyle(Color.cadenceAccent)
                        .tracking(1.5)

                    HStack(alignment: .lastTextBaseline, spacing: SpacingScale.lg) {
                        Text("25:00")
                            .font(.cadenceTimerHero)
                            .foregroundStyle(Color.cadenceAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hero Monospace Digits (64pt)")
                                .font(.cadenceHeadline)
                                .foregroundStyle(Color.cadenceTextPrimary)
                            Text(
                                "Tabular glyphs prevent horizontal layout jitter during countdown."
                            )
                            .font(.cadenceCaption)
                            .foregroundStyle(Color.cadenceTextSecondary)
                        }
                    }

                    Divider()
                        .background(Color.cadenceBorder)

                    HStack(spacing: SpacingScale.xl) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Large Title")
                                .font(.cadenceTitle)
                                .foregroundStyle(Color.cadenceTextPrimary)
                            Text("Section headers")
                                .font(.cadenceCaption)
                                .foregroundStyle(Color.cadenceTextTertiary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body Text")
                                .font(.cadenceBody)
                                .foregroundStyle(Color.cadenceTextPrimary)
                            Text("Standard 13pt macOS content")
                                .font(.cadenceCaption)
                                .foregroundStyle(Color.cadenceTextTertiary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Compact Digits 40pt")
                                .font(.cadenceTimerCompact)
                                .foregroundStyle(Color.cadenceTextPrimary)
                            Text("Menu bar & mini view")
                                .font(.cadenceCaption)
                                .foregroundStyle(Color.cadenceTextTertiary)
                        }
                    }
                }
            }

            // Palette Swatches
            CadenceCard {
                VStack(alignment: .leading, spacing: SpacingScale.md) {
                    Text("COLOR TOKENS & WCAG CONTRAST")
                        .font(.cadenceMicro)
                        .foregroundStyle(Color.cadenceAccent)
                        .tracking(1.5)

                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 140, maximum: 180), spacing: SpacingScale.md)
                        ], spacing: SpacingScale.md
                    ) {
                        ForEach(swatches, id: \.name) { swatch in
                            VStack(alignment: .leading, spacing: SpacingScale.xs) {
                                RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous)
                                    .fill(swatch.color)
                                    .frame(height: 38)
                                    .overlay(
                                        RoundedRectangle(
                                            cornerRadius: RadiusScale.md, style: .continuous
                                        )
                                        .stroke(Color.cadenceBorder, lineWidth: 0.5)
                                    )

                                Text(swatch.name)
                                    .font(.cadenceCaption)
                                    .foregroundStyle(Color.cadenceTextPrimary)
                                    .lineLimit(1)

                                Text(swatch.hex)
                                    .font(.cadenceMicro)
                                    .foregroundStyle(Color.cadenceTextSecondary)

                                let contrast = swatch.token.contrastRatio(
                                    against: BloodMoonPalette.background)
                                Text(String(format: "%.1f:1 vs bg", contrast))
                                    .font(.cadenceMicro)
                                    .foregroundStyle(
                                        contrast >= 4.5
                                            ? Color.cadenceMutedRose : Color.cadenceTextTertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(SpacingScale.xl)
    }
}
