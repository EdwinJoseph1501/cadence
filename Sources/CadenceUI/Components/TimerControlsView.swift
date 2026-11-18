import CadenceCore
import SwiftUI

/// Primary interactive controls for starting, pausing, resuming, and resetting countdown sessions, with audio alert toggle.
public struct TimerControlsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let phase: TimerPhase
    public let isAudioEnabled: Bool
    public let onToggle: () -> Void
    public let onReset: () -> Void
    public let onToggleAudio: (() -> Void)?

    @CadenceState private var isToggleHovered: Bool = false
    @CadenceState private var isResetHovered: Bool = false
    @CadenceState private var isAudioHovered: Bool = false

    public init(
        phase: TimerPhase,
        isAudioEnabled: Bool = true,
        onToggle: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onToggleAudio: (() -> Void)? = nil
    ) {
        self.phase = phase
        self.isAudioEnabled = isAudioEnabled
        self.onToggle = onToggle
        self.onReset = onReset
        self.onToggleAudio = onToggleAudio
    }

    private var toggleIcon: String {
        switch phase {
            case .idle, .paused:
                return "play.fill"
            case .running:
                return "pause.fill"
            case .completed:
                return "arrow.counterclockwise"
        }
    }

    private var toggleTitle: String {
        switch phase {
            case .idle:
                return "Start"
            case .running:
                return "Pause"
            case .paused:
                return "Resume"
            case .completed:
                return "Restart"
        }
    }

    public var body: some View {
        VStack(spacing: SpacingScale.sm) {
            HStack(spacing: SpacingScale.md) {
                // Audio alert toggle button
                if let onToggleAudio {
                    Button(action: onToggleAudio) {
                        Image(
                            systemName: isAudioEnabled
                                ? "speaker.wave.2.fill" : "speaker.slash.fill"
                        )
                        .font(.cadenceBody)
                        .foregroundStyle(
                            isAudioEnabled
                                ? (isAudioHovered
                                    ? Color.cadenceAccentHighlight : Color.cadenceTextSecondary)
                                : Color.cadenceTextSecondary.opacity(0.75)
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.cadenceSurfaceCard)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isAudioEnabled
                                        ? (isAudioHovered
                                            ? Color.cadenceAccent : Color.cadenceBorder)
                                        : Color.cadenceBorder.opacity(0.7),
                                    lineWidth: 1.0
                                )
                        )
                    }
                    .buttonStyle(TactileButtonStyle())
                    .onHover { isAudioHovered = $0 }
                    .accessibilityLabel("Completion sound")
                    .accessibilityValue(isAudioEnabled ? "Enabled" : "Muted")
                    .accessibilityHint(
                        isAudioEnabled
                            ? "Mutes completion chime. Keyboard shortcut Command Shift M"
                            : "Enables completion chime. Keyboard shortcut Command Shift M"
                    )
                    .accessibilityAddTraits(.isButton)
                }

                // Primary sculptural capsule button
                Button(action: onToggle) {
                    HStack(spacing: SpacingScale.xs) {
                        Image(systemName: toggleIcon)
                        Text(toggleTitle)
                    }
                    .font(.cadenceHeadline)
                    .foregroundStyle(Color.cadenceBackground)
                    .frame(minWidth: 140, minHeight: 46)
                    .padding(.horizontal, SpacingScale.md)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isToggleHovered
                                            ? Color.cadenceAccentHighlight : Color.cadenceAccent,
                                        Color.cadenceAccent,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(
                        color: isToggleHovered
                            ? Color.cadenceAccentHighlight.opacity(0.4)
                            : Color.cadenceAccent.opacity(0.2),
                        radius: isToggleHovered ? 10 : 5,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(TactileButtonStyle())
                .onHover { isToggleHovered = $0 }
                .accessibilityLabel("\(toggleTitle) timer")
                .accessibilityHint("Keyboard shortcut Space")
                .accessibilityAddTraits(.isButton)

                // Reset button
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.cadenceHeadline)
                        .foregroundStyle(
                            phase == .idle
                                ? Color.cadenceTextTertiary.opacity(0.6)
                                : (isResetHovered
                                    ? Color.cadenceTextPrimary : Color.cadenceTextSecondary)
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.cadenceSurfaceCard)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.cadenceBorder, lineWidth: 1.0)
                        )
                }
                .buttonStyle(TactileButtonStyle())
                .disabled(phase == .idle)
                .onHover { isResetHovered = $0 }
                .accessibilityLabel("Reset timer")
                .accessibilityHint("Keyboard shortcut Escape")
                .accessibilityAddTraits(.isButton)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: phase)

            Text("Space to toggle • Esc to reset")
                .font(.cadenceMicro)
                .foregroundStyle(Color.cadenceTextSecondary.opacity(0.85))
        }
    }
}

private struct TactileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
