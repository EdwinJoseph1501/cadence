import CadenceCore
import SwiftUI

extension Color {
    public init(token: ColorToken) {
        self.init(
            .sRGB,
            red: token.red,
            green: token.green,
            blue: token.blue,
            opacity: token.alpha
        )
    }

    // MARK: - Blood Moon Palette

    /// Deep blackish burgundy background (#140A10)
    public static let cadenceBackground = Color(token: BloodMoonPalette.background)

    /// Subtle elevated surface (#1D151B)
    public static let cadenceSurfaceElevated = Color(token: BloodMoonPalette.surfaceElevated)

    /// Rich card surface (#22141F)
    public static let cadenceSurfaceCard = Color(token: BloodMoonPalette.surfaceCard)

    /// Deep burgundy tone (#2D111E)
    public static let cadenceDeepBurgundy = Color(token: BloodMoonPalette.deepBurgundy)

    /// Subtle border separator (#3D2232)
    public static let cadenceBorder = Color(token: BloodMoonPalette.border)

    /// Primary text: Soft warm mist (#F2E8E8)
    public static let cadenceTextPrimary = Color(token: BloodMoonPalette.textPrimary)

    /// Secondary text: Muted rose quartz (#B09FA9)
    public static let cadenceTextSecondary = Color(token: BloodMoonPalette.textSecondary)

    /// Tertiary text: Subtle plum fog (#76646F)
    public static let cadenceTextTertiary = Color(token: BloodMoonPalette.textTertiary)

    /// Vivid blood crimson accent (#FF5268)
    public static let cadenceAccent = Color(token: BloodMoonPalette.accent)

    /// Restrained warm rose highlight (#FF8595)
    public static let cadenceAccentHighlight = Color(token: BloodMoonPalette.accentHighlight)

    /// Muted rose accent (#C88290)
    public static let cadenceMutedRose = Color(token: BloodMoonPalette.mutedRose)

    /// Success emerald tint (#50C878)
    public static let cadenceSuccess = Color(token: BloodMoonPalette.success)
}

extension Font {
    /// Hero countdown digits: 64pt tabular numbers, bold, monospaced
    public static let cadenceTimerHero = Font.system(
        size: TypographyScale.timerDigitsHero.pointSize,
        weight: .bold,
        design: .monospaced
    )

    /// Compact countdown digits: 40pt tabular numbers, bold, monospaced
    public static let cadenceTimerCompact = Font.system(
        size: TypographyScale.timerDigitsCompact.pointSize,
        weight: .semibold,
        design: .monospaced
    )

    /// Large window headers: 28pt
    public static let cadenceDisplay = Font.system(
        size: TypographyScale.displayLarge.pointSize,
        weight: .semibold,
        design: .default
    )

    /// Section titles: 20pt
    public static let cadenceTitle = Font.system(
        size: TypographyScale.titleLarge.pointSize,
        weight: .medium,
        design: .default
    )

    /// Card headings and subheaders: 15pt
    public static let cadenceHeadline = Font.system(
        size: TypographyScale.headline.pointSize,
        weight: .semibold,
        design: .default
    )

    /// Standard body text: 13pt (native macOS standard)
    public static let cadenceBody = Font.system(
        size: TypographyScale.body.pointSize,
        weight: .regular,
        design: .default
    )

    /// Secondary descriptions: 11pt
    public static let cadenceCaption = Font.system(
        size: TypographyScale.caption.pointSize,
        weight: .regular,
        design: .default
    )

    /// Micro labels and shortcuts: 10pt
    public static let cadenceMicro = Font.system(
        size: TypographyScale.micro.pointSize,
        weight: .medium,
        design: .default
    )
}
