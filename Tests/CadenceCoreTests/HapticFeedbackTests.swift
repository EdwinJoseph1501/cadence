import Foundation
import Testing

@testable import CadenceCore

@Suite("Haptic Feedback Contract Tests")
struct HapticFeedbackTests {
    @Test("MockHapticFeedback tracks performed patterns and clear")
    func testMockHapticFeedback() {
        let haptic = MockHapticFeedback()
        #expect(haptic.performedPatterns.isEmpty)

        haptic.perform(.generic)
        #expect(haptic.performedPatterns == [.generic])

        haptic.perform(.levelChange)
        haptic.perform(.completion)
        #expect(haptic.performedPatterns == [.generic, .levelChange, .completion])

        haptic.clear()
        #expect(haptic.performedPatterns.isEmpty)
    }

    @Test("NoOpHapticFeedback executes safely without error")
    func testNoOpHapticFeedback() {
        let haptic = NoOpHapticFeedback()
        haptic.perform(.alignment)
        haptic.perform(.completion)
        #expect(true)
    }

    @Test("HapticFeedbackPattern all cases verification")
    func testHapticFeedbackPatternCases() {
        #expect(HapticFeedbackPattern.allCases.count == 4)
        #expect(HapticFeedbackPattern.alignment.rawValue == "alignment")
        #expect(HapticFeedbackPattern.levelChange.rawValue == "levelChange")
        #expect(HapticFeedbackPattern.generic.rawValue == "generic")
        #expect(HapticFeedbackPattern.completion.rawValue == "completion")
    }
}
