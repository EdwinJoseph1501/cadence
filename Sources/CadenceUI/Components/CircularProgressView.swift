import CadenceCore
import SwiftUI

/// Reusable circular progress ring adhering to the Blood Moon design system.
public struct CircularProgressView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let progress: Double
    public let phase: TimerPhase
    public let diameter: CGFloat
    public let strokeWidth: CGFloat

    public init(
        progress: Double,
        phase: TimerPhase,
        diameter: CGFloat = 250,
        strokeWidth: CGFloat = 8
    ) {
        self.progress = progress
        self.phase = phase
        self.diameter = diameter
        self.strokeWidth = strokeWidth
    }

    private var clampedProgress: CGFloat {
        CGFloat(min(max(progress, 0.0), 1.0))
    }

    private var strokeColor: Color {
        switch phase {
            case .running:
                return Color.cadenceAccent
            case .paused:
                return Color.cadenceMutedRose
            case .completed:
                return Color.cadenceSuccess
            case .idle:
                return Color.cadenceBorder
        }
    }

    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.cadenceDeepBurgundy, lineWidth: strokeWidth)

            // Active progress arc
            if clampedProgress > 0.001 {
                Circle()
                    .trim(from: 0.0, to: clampedProgress)
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? nil : .linear(duration: 0.05),
                        value: progress
                    )
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timer progress")
        .accessibilityValue(String(format: "%.0f percent", clampedProgress * 100))
    }
}
