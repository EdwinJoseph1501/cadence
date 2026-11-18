import Foundation
import Testing

@testable import CadenceCore

@Suite("Timer Preset Tests")
struct TimerPresetTests {
    @Test("All presets are represented in CaseIterable")
    func testAllCases() {
        let expectedCases: [TimerPreset] = [
            .quick,
            .focus,
            .deepWork,
            .longSession,
            .custom,
        ]
        #expect(TimerPreset.allCases == expectedCases)
        #expect(TimerPreset.allCases.count == 5)
    }

    @Test("Raw value and identifier consistency")
    func testIdentifiersAndRawValues() {
        for preset in TimerPreset.allCases {
            #expect(preset.id == preset.rawValue)
            #expect(TimerPreset(rawValue: preset.rawValue) == preset)
        }
        #expect(TimerPreset(rawValue: "nonexistent") == nil)
    }

    @Test("Preset display names match expected strings")
    func testDisplayNames() {
        #expect(TimerPreset.quick.displayName == "Quick")
        #expect(TimerPreset.focus.displayName == "Focus")
        #expect(TimerPreset.deepWork.displayName == "Deep Work")
        #expect(TimerPreset.longSession.displayName == "Long Session")
        #expect(TimerPreset.custom.displayName == "Custom")
    }

    @Test("Preset default durations match exact seconds")
    func testDefaultDurations() {
        #expect(TimerPreset.quick.defaultDuration == 300)
        #expect(TimerPreset.focus.defaultDuration == 1500)
        #expect(TimerPreset.deepWork.defaultDuration == 3000)
        #expect(TimerPreset.longSession.defaultDuration == 5400)
        #expect(TimerPreset.custom.defaultDuration == 1500)
    }
}
