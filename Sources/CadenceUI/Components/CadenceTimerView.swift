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
            ZStack {
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

                HStack {
                    Spacer()
                    PinButton(
                        isPinned: store.isAlwaysOnTop,
                        onToggle: {
                            store.toggleAlwaysOnTop()
                        }
                    )
                }
            }

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

            if store.phase.isRunning || store.phase.isPaused {
                HStack(spacing: SpacingScale.md) {
                    adjustmentButton("−1m", seconds: -60)
                    Spacer(minLength: 0)
                    adjustmentButton("+1m", seconds: 60)
                    adjustmentButton("+5m", seconds: 300)
                }
                .padding(.horizontal, SpacingScale.lg)
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

            if store.phase.isRunning, let finish = store.estimatedFinishDate(at: date) {
                Text("Finishes at \(finish.formatted(date: .omitted, time: .shortened))")
                    .font(.cadenceMicro)
                    .foregroundStyle(Color.cadenceTextSecondary)
                    .accessibilityLabel(
                        "Expected finish time, \(finish.formatted(date: .omitted, time: .shortened))"
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onChange(of: remaining <= 0) { _, isExpired in
            if isExpired && store.phase.isRunning {
                store.evaluateDeadline(at: date)
            }
        }
    }

    private func adjustmentButton(_ title: String, seconds: TimeInterval) -> some View {
        Button(title) {
            store.adjustDuration(by: seconds)
        }
        .font(.cadenceBody)
        .foregroundStyle(Color.cadenceTextPrimary)
        .padding(.horizontal, SpacingScale.sm)
        .frame(minHeight: 30)
        .background(Color.cadenceSurfaceCard, in: Capsule())
        .overlay(Capsule().stroke(Color.cadenceBorder, lineWidth: 1))
        .disabled(!store.canAdjustDuration(by: seconds))
        .accessibilityLabel("\(seconds < 0 ? "Remove" : "Add") \(Int(abs(seconds) / 60)) minutes")
    }
}
