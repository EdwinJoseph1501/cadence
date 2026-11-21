import AppKit
import CadenceCore
import SwiftUI

/// Menu bar label view presenting real-time countdown digits during active sessions
/// and a static emblem when idle, maintaining 0.0% CPU when not ticking.
public struct CadenceMenuBarLabel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let store: TimerStore

    public init(store: TimerStore) {
        self.store = store
    }

    public var body: some View {
        if store.phase.isRunning {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let formatted = store.formattedCountdown(at: context.date)
                HStack(spacing: SpacingScale.xxs) {
                    Image(systemName: "timer")
                    Text(formatted)
                        .monospacedDigit()
                }
            }
        } else if store.phase.isPaused {
            HStack(spacing: SpacingScale.xxs) {
                Image(systemName: "pause.fill")
                Text(store.formattedCountdown())
                    .monospacedDigit()
            }
        } else if store.phase.isCompleted {
            HStack(spacing: SpacingScale.xxs) {
                Image(systemName: "bell.fill")
                Text("00:00")
                    .monospacedDigit()
            }
        } else {
            HStack(spacing: SpacingScale.xxs) {
                Image(systemName: "timer")
                Text("Cadence")
            }
        }
    }
}

/// Native macOS dropdown menu providing quick controls and window management from the menu bar.
public struct CadenceMenuBarMenu: View {
    public let store: TimerStore
    public let onOpenWindow: () -> Void
    public let onQuit: () -> Void

    public init(
        store: TimerStore,
        onOpenWindow: @escaping () -> Void = {
            WindowLifecycleController.shared.restoreMainWindow()
        },
        onQuit: @escaping () -> Void = {
            NSApp.terminate(nil)
        }
    ) {
        self.store = store
        self.onOpenWindow = onOpenWindow
        self.onQuit = onQuit
    }

    private var statusTitle: String {
        switch store.phase {
            case .idle:
                return "Cadence — Ready (\(store.selectedPreset.displayName))"
            case .running:
                return "Focus in Progress — \(store.formattedCountdown())"
            case .paused:
                return "Paused — \(store.formattedCountdown())"
            case .completed:
                return "Session Complete"
        }
    }

    private var toggleActionTitle: String {
        switch store.phase {
            case .idle:
                return "Start \(store.selectedPreset.displayName) (\(store.formattedCountdown()))"
            case .running:
                return "Pause"
            case .paused:
                return "Resume"
            case .completed:
                return "Restart Countdown"
        }
    }

    public var body: some View {
        Text(statusTitle)
            .font(.headline)

        Divider()

        Button(toggleActionTitle) {
            store.toggle()
        }

        Button("Reset Timer") {
            store.reset()
        }
        .disabled(store.phase.isIdle)

        if let finish = store.estimatedFinishDate() {
            Text(
                store.phase.isPaused
                    ? "If resumed now, finishes at \(finish.formatted(date: .omitted, time: .shortened))"
                    : "Finishes at \(finish.formatted(date: .omitted, time: .shortened))"
            )
            Divider()
            Button("Remove 1 Minute") { store.adjustDuration(by: -60) }
                .disabled(!store.canAdjustDuration(by: -60))
            Button("Add 1 Minute") { store.adjustDuration(by: 60) }
                .disabled(!store.canAdjustDuration(by: 60))
            Button("Add 5 Minutes") { store.adjustDuration(by: 300) }
                .disabled(!store.canAdjustDuration(by: 300))
        }

        Divider()

        Menu("Presets") {
            ForEach(TimerPreset.allCases) { preset in
                if preset != .custom {
                    Button {
                        store.selectPreset(preset)
                    } label: {
                        HStack {
                            Text("\(preset.displayName) (\(Int(preset.defaultDuration / 60))m)")
                            if store.selectedPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .disabled(store.phase.isRunning)

        Divider()

        Button(store.isAlwaysOnTop ? "✓ Keep Window on Top" : "Keep Window on Top") {
            store.toggleAlwaysOnTop()
        }

        Button(store.isAudioAlertEnabled ? "✓ Audio Alert Chime" : "Audio Alert Chime") {
            store.toggleAudioAlert()
        }

        Button(store.isHapticsEnabled ? "✓ Trackpad Haptics" : "Trackpad Haptics") {
            store.toggleHaptics()
        }

        Divider()

        Button("Settings...") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        Button("Open Cadence Window") {
            onOpenWindow()
        }

        Divider()

        Button("Quit Cadence") {
            onQuit()
        }
    }
}
