import Foundation

/// Pure token definitions for typography sizing, weights, and letter spacing.
public struct TypographyToken: Sendable, Equatable {
    public let pointSize: Double
    public let lineSpacing: Double
    public let letterSpacing: Double
    public let isMonospaced: Bool

    public init(
        pointSize: Double,
        lineSpacing: Double = 0.0,
        letterSpacing: Double = 0.0,
        isMonospaced: Bool = false
    ) {
        self.pointSize = pointSize
        self.lineSpacing = lineSpacing
        self.letterSpacing = letterSpacing
        self.isMonospaced = isMonospaced
    }
}

public enum TypographyScale: Sendable {
    /// Hero display size for countdown timer digits (64pt tabular monospace)
    public static let timerDigitsHero = TypographyToken(
        pointSize: 64.0,
        lineSpacing: 0.0,
        letterSpacing: -1.0,
        isMonospaced: true
    )

    /// Compact display size for timer digits in smaller panels or menu bar popover (40pt)
    public static let timerDigitsCompact = TypographyToken(
        pointSize: 40.0,
        lineSpacing: 0.0,
        letterSpacing: -0.5,
        isMonospaced: true
    )

    /// Large window headers (28pt)
    public static let displayLarge = TypographyToken(pointSize: 28.0, lineSpacing: 4.0)

    /// Section titles (20pt)
    public static let titleLarge = TypographyToken(pointSize: 20.0, lineSpacing: 2.0)

    /// Card headings and subheaders (15pt)
    public static let headline = TypographyToken(pointSize: 15.0, lineSpacing: 2.0)

    /// Standard body text (13pt, native macOS standard)
    public static let body = TypographyToken(pointSize: 13.0, lineSpacing: 3.0)

    /// Secondary descriptions and captions (11pt)
    public static let caption = TypographyToken(pointSize: 11.0, lineSpacing: 1.5)

    /// Micro labels and shortcuts (10pt)
    public static let micro = TypographyToken(pointSize: 10.0, lineSpacing: 1.0)
}
