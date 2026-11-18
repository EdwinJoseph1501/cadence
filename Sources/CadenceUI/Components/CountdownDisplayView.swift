import CadenceCore
import SwiftUI

/// Hero countdown digits and state indicator label conforming to Blood Moon typography tokens.
public struct CountdownDisplayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let formattedTime: String
    public let phase: TimerPhase
    public let remainingDuration: TimeInterval?

    public init(
        formattedTime: String,
        phase: TimerPhase,
        remainingDuration: TimeInterval? = nil
    ) {
        self.formattedTime = formattedTime
        self.phase = phase
        self.remainingDuration = remainingDuration
    }

    private var digitsColor: Color {
        switch phase {
            case .running, .idle:
                return Color.cadenceTextPrimary
            case .paused:
                return Color.cadenceMutedRose
            case .completed:
                return Color.cadenceSuccess
        }
    }

    private var statusSubtitle: String {
        switch phase {
            case .running:
                return "FOCUS SESSION"
            case .paused:
                return "PAUSED"
            case .completed:
                return "COMPLETED"
            case .idle:
                return "READY"
        }
    }

    private var statusColor: Color {
        switch phase {
            case .running:
                return Color.cadenceAccent
            case .paused:
                return Color.cadenceMutedRose
            case .completed:
                return Color.cadenceSuccess
            case .idle:
                return Color.cadenceTextSecondary.opacity(0.85)
        }
    }

    private var phaseDescription: String {
        switch phase {
            case .running:
                return "focus session in progress"
            case .paused:
                return "paused"
            case .completed:
                return "session complete"
            case .idle:
                return "ready"
        }
    }

    private var accessibleTimeDescription: String {
        if let remainingDuration {
            return TimerEngineCalculations.accessibleDuration(remainingDuration)
        }
        return formattedTime
    }

    public var body: some View {
        VStack(spacing: SpacingScale.xs) {
            Text(formattedTime)
                .font(.cadenceTimerHero)
                .foregroundStyle(digitsColor)
                .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: 2)

            Text(statusSubtitle)
                .font(.cadenceMicro)
                .tracking(2.0)
                .foregroundStyle(statusColor)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: phase)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibleTimeDescription), \(phaseDescription)")
        .accessibilityAddTraits(phase.isRunning ? [.updatesFrequently] : [])
    }
}
