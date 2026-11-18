import CadenceCore
import SwiftUI

/// Tactile toggle button controlling the always-on-top floating window level.
public struct PinButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let isPinned: Bool
    public let onToggle: () -> Void

    @CadenceState private var isHovered: Bool = false

    public init(
        isPinned: Bool,
        onToggle: @escaping () -> Void
    ) {
        self.isPinned = isPinned
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 11, weight: isPinned ? .semibold : .regular))
                .rotationEffect(isPinned ? .degrees(0) : .degrees(45))
                .foregroundStyle(
                    isPinned
                        ? Color.cadenceAccent
                        : (isHovered ? Color.cadenceTextPrimary : Color.cadenceTextSecondary)
                )
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(
                        cornerRadius: RadiusScale.sm,
                        style: .continuous
                    )
                    .fill(
                        isPinned
                            ? Color.cadenceAccent.opacity(0.14)
                            : (isHovered
                                ? Color.cadenceSurfaceCard.opacity(0.9)
                                : Color.cadenceSurfaceCard)
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: RadiusScale.sm,
                        style: .continuous
                    )
                    .stroke(
                        isPinned ? Color.cadenceAccent.opacity(0.85) : Color.cadenceBorder,
                        lineWidth: 1.0
                    )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(isPinned ? "Unpin Window (⌘P)" : "Keep Window on Top (⌘P)")
        .accessibilityLabel(isPinned ? "Unpin window from top" : "Pin window always on top")
        .accessibilityHint("Toggles floating window level. Keyboard shortcut Command P")
        .accessibilityAddTraits(isPinned ? [.isSelected, .isButton] : [.isButton])
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isPinned)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
    }
}
