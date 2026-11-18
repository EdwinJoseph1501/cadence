import CadenceCore
import SwiftUI

/// Modal sheet or popover for entering custom countdown durations.
public struct CustomDurationSheet: View {
    @Binding public var isPresented: Bool
    public let currentDuration: TimeInterval
    public let onSave: (TimeInterval) -> Void

    @CadenceState private var minutes: Int
    @CadenceState private var seconds: Int
    @CadenceState private var isCancelHovered: Bool = false
    @CadenceState private var isSetHovered: Bool = false

    public init(
        isPresented: Binding<Bool>,
        currentDuration: TimeInterval,
        onSave: @escaping (TimeInterval) -> Void
    ) {
        self._isPresented = isPresented
        self.currentDuration = currentDuration
        self.onSave = onSave

        let total = max(0, Int(currentDuration))
        let initialMinutes = total / 60
        let initialSeconds = total % 60
        self._minutes = CadenceState(initialValue: initialMinutes)
        self._seconds = CadenceState(initialValue: initialSeconds)
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(max(0, minutes) * 60 + max(0, seconds))
    }

    private var isValid: Bool {
        totalSeconds > 0 && totalSeconds <= 86_400
    }

    private var errorMessage: String? {
        if totalSeconds <= 0 {
            return "Duration must be greater than 0 seconds."
        } else if totalSeconds > 86_400 {
            return "Duration cannot exceed 24 hours."
        }
        return nil
    }

    public var body: some View {
        VStack(spacing: SpacingScale.lg) {
            Text("Custom Duration")
                .font(.cadenceHeadline)
                .foregroundStyle(Color.cadenceTextPrimary)

            HStack(spacing: SpacingScale.xl) {
                durationField(
                    label: "Minutes",
                    value: $minutes,
                    range: 0...180
                )

                durationField(
                    label: "Seconds",
                    value: $seconds,
                    range: 0...59
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.cadenceCaption)
                    .foregroundStyle(Color.cadenceAccent)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Validation error: \(errorMessage)")
                    .accessibilityAddTraits(.isStaticText)
            }

            HStack(spacing: SpacingScale.md) {
                Button("Cancel") {
                    isPresented = false
                }
                .font(.cadenceBody)
                .foregroundStyle(
                    isCancelHovered ? Color.cadenceTextPrimary : Color.cadenceTextSecondary
                )
                .padding(.horizontal, SpacingScale.md)
                .padding(.vertical, SpacingScale.sm)
                .background(Color.cadenceBackground)
                .clipShape(RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous)
                        .stroke(Color.cadenceBorder, lineWidth: 1.0)
                )
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .onHover { isCancelHovered = $0 }
                .accessibilityLabel("Cancel custom duration")
                .accessibilityHint("Dismisses dialog without saving. Keyboard shortcut Escape")
                .accessibilityAddTraits(.isButton)

                Button("Set Duration") {
                    guard isValid else { return }
                    onSave(totalSeconds)
                    isPresented = false
                }
                .font(.cadenceHeadline)
                .foregroundStyle(
                    isValid ? Color.cadenceBackground : Color.cadenceTextSecondary.opacity(0.5)
                )
                .padding(.horizontal, SpacingScale.lg)
                .padding(.vertical, SpacingScale.sm)
                .background(
                    RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous)
                        .fill(
                            isValid
                                ? (isSetHovered
                                    ? Color.cadenceAccentHighlight : Color.cadenceAccent)
                                : Color.cadenceBorder
                        )
                )
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .onHover { isSetHovered = $0 }
                .accessibilityLabel("Set custom duration")
                .accessibilityHint("Applies entered duration to timer. Keyboard shortcut Return")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(SpacingScale.xl)
        .frame(minWidth: 300, minHeight: 220)
        .background(Color.cadenceSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: RadiusScale.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RadiusScale.lg, style: .continuous)
                .stroke(Color.cadenceBorder, lineWidth: 1.0)
        )
    }

    private func durationField(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(spacing: SpacingScale.xs) {
            Text(label)
                .font(.cadenceCaption)
                .foregroundStyle(Color.cadenceTextSecondary)

            HStack(spacing: SpacingScale.xs) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.cadenceHeadline)
                        .foregroundStyle(Color.cadenceTextSecondary)
                        .frame(
                            width: SpacingScale.xl + SpacingScale.sm,
                            height: SpacingScale.xl + SpacingScale.sm
                        )
                        .background(Color.cadenceBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.cadenceBorder, lineWidth: 1.0))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue <= range.lowerBound)
                .accessibilityLabel("Decrease \(label.lowercased())")
                .accessibilityHint("Decreases \(label.lowercased()) by 1")
                .accessibilityAddTraits(.isButton)

                TextField("", value: value, format: .number)
                    .font(.cadenceDisplay)
                    .foregroundStyle(Color.cadenceTextPrimary)
                    .multilineTextAlignment(.center)
                    .frame(
                        width: SpacingScale.xxxl + SpacingScale.lg,
                        height: SpacingScale.xxl + SpacingScale.sm
                    )
                    .background(Color.cadenceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: RadiusScale.md, style: .continuous)
                            .stroke(Color.cadenceBorder, lineWidth: 1.0)
                    )
                    .accessibilityLabel("\(label) duration")
                    .accessibilityValue("\(value.wrappedValue) \(label.lowercased())")
                    .accessibilityHint(
                        "Enter value between \(range.lowerBound) and \(range.upperBound)")

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.cadenceHeadline)
                        .foregroundStyle(Color.cadenceTextSecondary)
                        .frame(
                            width: SpacingScale.xl + SpacingScale.sm,
                            height: SpacingScale.xl + SpacingScale.sm
                        )
                        .background(Color.cadenceBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.cadenceBorder, lineWidth: 1.0))
                }
                .buttonStyle(.plain)
                .disabled(value.wrappedValue >= range.upperBound)
                .accessibilityLabel("Increase \(label.lowercased())")
                .accessibilityHint("Increases \(label.lowercased()) by 1")
                .accessibilityAddTraits(.isButton)
            }
        }
    }
}
