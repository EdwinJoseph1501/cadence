import Foundation

/// Mathematical spacing scale for consistent padding, margins, and layout gutters.
public enum SpacingScale: Sendable {
    /// 2pt: Micro spacing (sub-pixel alignment, hairline dividers)
    public static let xxs: Double = 2.0

    /// 4pt: Tight spacing (badge margins, icon-to-text gap)
    public static let xs: Double = 4.0

    /// 8pt: Compact spacing (button inner padding, list item gaps)
    public static let sm: Double = 8.0

    /// 12pt: Medium spacing (card inner padding, input field padding)
    public static let md: Double = 12.0

    /// 16pt: Standard spacing (group margins, container padding)
    public static let lg: Double = 16.0

    /// 24pt: Generous spacing (section breaks, modal padding)
    public static let xl: Double = 24.0

    /// 32pt: Wide spacing (major window quadrant separation)
    public static let xxl: Double = 32.0

    /// 48pt: Hero spacing (countdown timer vertical padding)
    public static let xxxl: Double = 48.0
}
