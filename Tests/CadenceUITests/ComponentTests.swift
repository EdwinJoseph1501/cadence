import CadenceCore
import CadenceUI
import Foundation
import SwiftUI
import Testing

@Suite("CadenceUI Component Integration Tests")
@MainActor
struct ComponentTests {
    @Test("CircularProgressView initializes with valid parameters across all phases")
    func testCircularProgressViewPhases() {
        let phases: [TimerPhase] = [
            .idle,
            .running(targetDeadline: Date().addingTimeInterval(300), totalDuration: 300),
            .paused(remainingDuration: 150, totalDuration: 300),
            .completed(completedAt: Date(), totalDuration: 300),
        ]

        for phase in phases {
            let view = CircularProgressView(
                progress: 0.5,
                phase: phase,
                diameter: 250,
                strokeWidth: 8
            )
            #expect(view.progress == 0.5)
            #expect(view.diameter == 250)
            #expect(view.strokeWidth == 8)
            #expect(view.phase == phase)
        }
    }

    @Test("ChronoSculptView initializes with valid parameters across all phases")
    func testChronoSculptViewPhases() {
        let phases: [TimerPhase] = [
            .idle,
            .running(targetDeadline: Date().addingTimeInterval(300), totalDuration: 300),
            .paused(remainingDuration: 150, totalDuration: 300),
            .completed(completedAt: Date(), totalDuration: 300),
        ]

        let defaultView = ChronoSculptView(progress: 0.5, phase: .idle)
        #expect(defaultView.diameter == 304)

        for phase in phases {
            let view = ChronoSculptView(
                progress: 0.75,
                phase: phase,
                diameter: 304,
                timestamp: 42.0
            )
            #expect(view.progress == 0.75)
            #expect(view.diameter == 304)
            #expect(view.timestamp == 42.0)
            #expect(view.phase == phase)
        }
    }

    @Test("CountdownDisplayView initializes across all phases")
    func testCountdownDisplayView() {
        let viewIdle = CountdownDisplayView(formattedTime: "25:00", phase: .idle)
        #expect(viewIdle.formattedTime == "25:00")
        #expect(viewIdle.phase == .idle)

        let viewRunning = CountdownDisplayView(
            formattedTime: "24:59",
            phase: .running(targetDeadline: Date().addingTimeInterval(1499), totalDuration: 1500)
        )
        #expect(viewRunning.formattedTime == "24:59")
        #expect(viewRunning.phase.isRunning)

        let viewPaused = CountdownDisplayView(
            formattedTime: "12:30",
            phase: .paused(remainingDuration: 750, totalDuration: 1500)
        )
        #expect(viewPaused.formattedTime == "12:30")
        #expect(viewPaused.phase.isPaused)

        let viewCompleted = CountdownDisplayView(
            formattedTime: "00:00",
            phase: .completed(completedAt: Date(), totalDuration: 1500)
        )
        #expect(viewCompleted.formattedTime == "00:00")
        #expect(viewCompleted.phase.isCompleted)

        let viewWithDuration = CountdownDisplayView(
            formattedTime: "04:59",
            phase: .running(targetDeadline: Date().addingTimeInterval(299), totalDuration: 300),
            remainingDuration: 299
        )
        #expect(viewWithDuration.formattedTime == "04:59")
        #expect(viewWithDuration.remainingDuration == 299)
        #expect(viewWithDuration.phase.isRunning)
    }

    @Test("PresetSelectorView reflects selection state and isRunning disabled state")
    func testPresetSelectorView() {
        var selected: TimerPreset?
        var customTapped = false

        let selector = PresetSelectorView(
            selectedPreset: .focus,
            isRunning: false,
            onSelect: { selected = $0 },
            onCustomTapped: { customTapped = true }
        )

        #expect(selector.selectedPreset == .focus)
        #expect(!selector.isRunning)

        selector.onSelect(.deepWork)
        #expect(selected == .deepWork)

        selector.onCustomTapped()
        #expect(customTapped)
    }

    @Test("CustomDurationSheet accepts valid duration and triggers onSave")
    func testCustomDurationSheet() {
        var isPresented = true
        var savedDuration: TimeInterval?

        let sheet = CustomDurationSheet(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            currentDuration: 1500,
            onSave: { savedDuration = $0 }
        )

        #expect(sheet.currentDuration == 1500)
        #expect(isPresented)

        sheet.onSave(1800)
        #expect(savedDuration == 1800)
    }

    @Test("TimerControlsView triggers toggle, reset, and audio closures")
    func testTimerControlsView() {
        var toggled = false
        var reset = false
        var audioToggled = false

        let controls = TimerControlsView(
            phase: .idle,
            isAudioEnabled: true,
            onToggle: { toggled = true },
            onReset: { reset = true },
            onToggleAudio: { audioToggled = true }
        )

        #expect(controls.phase == .idle)
        #expect(controls.isAudioEnabled == true)

        controls.onToggle()
        #expect(toggled)

        controls.onReset()
        #expect(reset)

        controls.onToggleAudio?()
        #expect(audioToggled)
    }

    @Test("CadenceTimerView integrates with TimerStore")
    func testCadenceTimerViewIntegration() {
        let store = TimerStore()
        let timerView = CadenceTimerView(store: store)

        #expect(timerView.store.phase == .idle)
        #expect(timerView.store.selectedPreset == .focus)
        #expect(timerView.store.remainingDuration() == 1500)
    }

    @Test("TimerControlsView exposes correct state for audio enabled and muted")
    func testTimerControlsAudioStates() {
        let controlsMuted = TimerControlsView(
            phase: .running(targetDeadline: Date().addingTimeInterval(100), totalDuration: 100),
            isAudioEnabled: false,
            onToggle: {},
            onReset: {},
            onToggleAudio: {}
        )
        #expect(!controlsMuted.isAudioEnabled)
        #expect(controlsMuted.phase.isRunning)
    }
}
