import CadenceCore
import SwiftUI

/// Top-level composite countdown timer interface integrating the generative ChronoSculptView, preset selectors, and interactive controls.
public struct CadenceTimerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let store: TimerStore

    public init(store: TimerStore) {
        self.store = store
    }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { store.isCustomSheetPresented },
            set: { store.isCustomSheetPresented = $0 }
        )
    }

    public var body: some View {
        VStack(spacing: SpacingScale.md) {
            PresetSelectorView(
                selectedPreset: store.selectedPreset,
                isRunning: store.phase.isRunning,
                onSelect: { preset in
                    store.selectPreset(preset)
                },
                onCustomTapped: {
                    store.isCustomSheetPresented = true
                }
            )

            if reduceMotion {
                if store.phase.isRunning {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        timerDisplay(for: context.date)
                    }
                } else {
                    timerDisplay(for: .now)
                }
            } else {
                TimelineView(.animation(paused: !store.phase.isRunning)) { context in
                    timerDisplay(for: context.date)
                }
            }

            TimerControlsView(
                phase: store.phase,
                isAudioEnabled: store.isAudioAlertEnabled,
                onToggle: {
                    store.toggle()
                },
                onReset: {
                    store.reset()
                },
                onToggleAudio: {
                    store.toggleAudioAlert()
                }
            )
        }
        .padding(.horizontal, SpacingScale.lg)
        .padding(.vertical, SpacingScale.md)
        .sheet(isPresented: sheetBinding) {
            CustomDurationSheet(
                isPresented: sheetBinding,
                currentDuration: store.activeDuration,
                onSave: { newDuration in
                    store.setCustomDuration(newDuration)
                }
            )
        }
    }

    @ViewBuilder
    private func timerDisplay(for date: Date) -> some View {
        let remaining = store.remainingDuration(at: date)
        let progress = store.progressFraction(at: date)
        let formatted = store.formattedCountdown(at: date)
        let timestamp = date.timeIntervalSinceReferenceDate

        ZStack {
            ChronoSculptView(
                progress: progress,
                phase: store.phase,
                diameter: 304,
                timestamp: timestamp
            )

            CountdownDisplayView(
                formattedTime: formatted,
                phase: store.phase,
                remainingDuration: remaining
            )
        }
        .onChange(of: remaining <= 0) { _, isExpired in
            if isExpired && store.phase.isRunning {
                store.evaluateDeadline(at: date)
            }
        }
    }
}
