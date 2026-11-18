import Foundation

/// Corner radius tokens adhering to macOS squircle / rounded rectangle conventions.
public enum RadiusScale: Sendable {
    /// 0pt: Sharp corners
    public static let none: Double = 0.0

    /// 4pt: Subtle rounding for tiny tags, indicators, and tooltips
    public static let sm: Double = 4.0

    /// 8pt: Standard control radius (buttons, text fields, menu highlights)
    public static let md: Double = 8.0

    /// 12pt: Secondary container radius (inner cards, preset chips)
    public static let lg: Double = 12.0

    /// 16pt: Primary container radius (floating panels, popovers, main card)
    public static let xl: Double = 16.0

    /// 9999pt: Fully rounded pill shape (capsule buttons, progress track caps)
    public static let full: Double = 9999.0
}
