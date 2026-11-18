import Foundation

/// Pure Swift representation of RGBA color values for the design system.
///
/// Decoupled from AppKit / SwiftUI to enable cross-module accessibility audits,
/// serialization, and headless testing without window server dependencies.
public struct ColorToken: Sendable, Equatable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = min(max(red, 0.0), 1.0)
        self.green = min(max(green, 0.0), 1.0)
        self.blue = min(max(blue, 0.0), 1.0)
        self.alpha = min(max(alpha, 0.0), 1.0)
    }

    /// Initializes a ColorToken from a 6-digit hex string (e.g. "#140A10" or "140A10").
    public init?(hex: String, alpha: Double = 1.0) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return nil
        }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// Relative luminance in the sRGB color space according to WCAG 2.1 specifications.
    public var relativeLuminance: Double {
        func channelLuminance(_ channel: Double) -> Double {
            if channel <= 0.04045 {
                return channel / 12.92
            } else {
                return pow((channel + 0.055) / 1.055, 2.4)
            }
        }
        let r = channelLuminance(red)
        let g = channelLuminance(green)
        let b = channelLuminance(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Computes the WCAG 2.1 contrast ratio against another ColorToken (returns value between 1.0 and 21.0).
    public func contrastRatio(against other: ColorToken) -> Double {
        let l1 = max(relativeLuminance, other.relativeLuminance)
        let l2 = min(relativeLuminance, other.relativeLuminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }
}

/// Palette tokens for the "Blood Moon" design theme.
public enum BloodMoonPalette: Sendable {
    /// Background: Deep blackish burgundy (#140A10)
    public static let background = ColorToken(hex: "#140A10")!

    /// Primary surface elevated: Subtle plum charcoal (#1D151B)
    public static let surfaceElevated = ColorToken(hex: "#1D151B")!

    /// Card / Panel surface: Rich deep burgundy (#22141F)
    public static let surfaceCard = ColorToken(hex: "#22141F")!

    /// Deep burgundy tone: (#2D111E)
    public static let deepBurgundy = ColorToken(hex: "#2D111E")!

    /// Subtle border separator: (#3D2232)
    public static let border = ColorToken(hex: "#3D2232")!

    /// Primary text: Soft warm mist (#F2E8E8)
    public static let textPrimary = ColorToken(hex: "#F2E8E8")!

    /// Secondary text: Muted rose quartz (#B09FA9)
    public static let textSecondary = ColorToken(hex: "#B09FA9")!

    /// Tertiary text: Subtle plum fog (#76646F)
    public static let textTertiary = ColorToken(hex: "#76646F")!

    /// Brand accent: Vivid blood crimson (#FF5268)
    public static let accent = ColorToken(hex: "#FF5268")!

    /// Accent highlight: Restrained warm rose highlight (#FF8595)
    public static let accentHighlight = ColorToken(hex: "#FF8595")!

    /// Muted rose accent for calm states (#C88290)
    public static let mutedRose = ColorToken(hex: "#C88290")!

    /// Success / Complete accent: Restrained warm emerald tint (#50C878)
    public static let success = ColorToken(hex: "#50C878")!
}
