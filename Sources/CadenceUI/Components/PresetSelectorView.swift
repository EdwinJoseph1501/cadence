import CadenceCore
import SwiftUI

/// Preset selection chips allowing instant duration switching between focus intervals.
public struct PresetSelectorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let selectedPreset: TimerPreset
    public let isRunning: Bool
    public let onSelect: (TimerPreset) -> Void
    public let onCustomTapped: () -> Void

    @CadenceState private var hoveredPreset: TimerPreset? = nil

    public init(
        selectedPreset: TimerPreset,
        isRunning: Bool,
        onSelect: @escaping (TimerPreset) -> Void,
        onCustomTapped: @escaping () -> Void
    ) {
        self.selectedPreset = selectedPreset
        self.isRunning = isRunning
        self.onSelect = onSelect
        self.onCustomTapped = onCustomTapped
    }

    private func compactTitle(for preset: TimerPreset) -> String {
        switch preset {
            case .quick:
                return "5m"
            case .focus:
                return "25m"
            case .deepWork:
                return "50m"
            case .longSession:
                return "90m"
            case .custom:
                return "Custom"
        }
    }

    private func accessibilityLabel(for preset: TimerPreset) -> String {
        switch preset {
            case .quick:
                return "Quick 5 minutes preset"
            case .focus:
                return "Focus 25 minutes preset"
            case .deepWork:
                return "Deep work 50 minutes preset"
            case .longSession:
                return "Long session 90 minutes preset"
            case .custom:
                return "Custom duration preset"
        }
    }

    private func accessibilityHint(for preset: TimerPreset) -> String {
        if isRunning {
            return "Presets are locked while a countdown is running"
        }
        switch preset {
            case .quick:
                return "Sets timer to 5 minutes. Keyboard shortcut Command 1"
            case .focus:
                return "Sets timer to 25 minutes. Keyboard shortcut Command 2"
            case .deepWork:
                return "Sets timer to 50 minutes. Keyboard shortcut Command 3"
            case .longSession:
                return "Sets timer to 90 minutes. Keyboard shortcut Command 4"
            case .custom:
                return "Opens custom duration dialog"
        }
    }

    public var body: some View {
        HStack(spacing: SpacingScale.xs) {
            ForEach(TimerPreset.allCases) { preset in
                let isSelected = preset == selectedPreset
                let isHovered = preset == hoveredPreset

                Button {
                    if preset == .custom {
                        onCustomTapped()
                    } else {
                        onSelect(preset)
                    }
                } label: {
                    VStack(spacing: SpacingScale.xxs) {
                        Text(compactTitle(for: preset))
                            .font(.cadenceCaption)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .foregroundStyle(
                                isSelected
                                    ? Color.cadenceAccent
                                    : (isHovered
                                        ? Color.cadenceTextPrimary
                                        : Color.cadenceTextPrimary.opacity(0.76))
                            )

                        // Subtle active indicator dot under selected preset (3.5pt)
                        Circle()
                            .fill(isSelected ? Color.cadenceAccent : Color.clear)
                            .frame(width: 3.5, height: 3.5)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(
                            cornerRadius: RadiusScale.sm,
                            style: .continuous
                        )
                        .fill(
                            isSelected
                                ? Color.cadenceAccent.opacity(0.14)
                                : Color.cadenceSurfaceCard
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: RadiusScale.sm,
                            style: .continuous
                        )
                        .stroke(
                            isSelected ? Color.cadenceAccent.opacity(0.85) : Color.cadenceBorder,
                            lineWidth: 1.0
                        )
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredPreset = hovering ? preset : nil
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel(for: preset))
                .accessibilityHint(accessibilityHint(for: preset))
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
            }
        }
        .disabled(isRunning)
        .opacity(isRunning ? 0.75 : 1.0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isRunning)
    }
}
