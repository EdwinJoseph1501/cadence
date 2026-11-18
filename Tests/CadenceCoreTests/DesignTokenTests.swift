import Testing

@testable import CadenceCore

@Suite("Design Token Foundation Tests")
struct DesignTokenTests {
    @Test("Hex parsing creates accurate normalized RGB values")
    func testHexParsing() {
        let bg = ColorToken(hex: "#140A10")
        #expect(bg != nil)
        #expect(abs(bg!.red - (20.0 / 255.0)) < 0.001)
        #expect(abs(bg!.green - (10.0 / 255.0)) < 0.001)
        #expect(abs(bg!.blue - (16.0 / 255.0)) < 0.001)

        let accent = ColorToken(hex: "#FF5268")
        #expect(accent != nil)
        #expect(abs(accent!.red - 1.0) < 0.001)
    }

    @Test("Invalid hex returns nil")
    func testInvalidHex() {
        #expect(ColorToken(hex: "invalid") == nil)
        #expect(ColorToken(hex: "#12") == nil)
        #expect(ColorToken(hex: "#ZZZZZZ") == nil)
    }

    @Test("Primary text meets WCAG AAA contrast against Blood Moon background")
    func testPrimaryTextContrast() {
        let bg = BloodMoonPalette.background
        let primaryText = BloodMoonPalette.textPrimary
        let contrast = primaryText.contrastRatio(against: bg)

        // WCAG AAA requires 7.0:1 for normal text. Cadence achieves > 13:1.
        #expect(contrast >= 7.0)
    }

    @Test("Secondary text meets WCAG AA contrast against Blood Moon background")
    func testSecondaryTextContrast() {
        let bg = BloodMoonPalette.background
        let secondaryText = BloodMoonPalette.textSecondary
        let contrast = secondaryText.contrastRatio(against: bg)

        // WCAG AA requires 4.5:1 for normal text.
        #expect(contrast >= 4.5)
    }

    @Test("Spacing scale maintains monotonic progression")
    func testSpacingScale() {
        #expect(SpacingScale.xxs < SpacingScale.xs)
        #expect(SpacingScale.xs < SpacingScale.sm)
        #expect(SpacingScale.sm < SpacingScale.md)
        #expect(SpacingScale.md < SpacingScale.lg)
        #expect(SpacingScale.lg < SpacingScale.xl)
        #expect(SpacingScale.xl < SpacingScale.xxl)
        #expect(SpacingScale.xxl < SpacingScale.xxxl)
    }

    @Test("Corner radius scale maintains proper hierarchy")
    func testRadiusScale() {
        #expect(RadiusScale.none == 0.0)
        #expect(RadiusScale.sm == 4.0)
        #expect(RadiusScale.md == 8.0)
        #expect(RadiusScale.lg == 12.0)
        #expect(RadiusScale.xl == 16.0)
        #expect(RadiusScale.full > 1000.0)
    }
}
