import AppKit
import CadenceCore

/// Native macOS haptic feedback performer leveraging trackpad vibration via NSHapticFeedbackManager.
public final class AppKitHapticFeedback: HapticFeedbackProtocol, @unchecked Sendable {
    public init() {}

    public func perform(_ pattern: HapticFeedbackPattern) {
        let performer = NSHapticFeedbackManager.defaultPerformer
        switch pattern {
            case .alignment:
                performer.perform(.alignment, performanceTime: .default)
            case .levelChange:
                performer.perform(.levelChange, performanceTime: .default)
            case .generic:
                performer.perform(.generic, performanceTime: .default)
            case .completion:
                performer.perform(.levelChange, performanceTime: .default)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    performer.perform(.alignment, performanceTime: .default)
                }
        }
    }
}
