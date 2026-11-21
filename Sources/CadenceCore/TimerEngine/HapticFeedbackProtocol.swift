import Foundation

/// Sensory feedback patterns supported by Cadence's tactile engine.
public enum HapticFeedbackPattern: String, Sendable, CaseIterable, Equatable {
    case alignment
    case levelChange
    case generic
    case completion
}

/// Pure contract for triggering tactile trackpad haptic feedback.
///
/// Decoupled from AppKit to ensure CadenceCore remains pure Swift.
public protocol HapticFeedbackProtocol: Sendable {
    func perform(_ pattern: HapticFeedbackPattern)
}

/// No-op haptic feedback performer for previews and non-macOS environments.
public struct NoOpHapticFeedback: HapticFeedbackProtocol {
    public init() {}
    public func perform(_ pattern: HapticFeedbackPattern) {}
}

/// Mock haptic feedback performer recording haptic triggers for deterministic unit tests.
public final class MockHapticFeedback: HapticFeedbackProtocol, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var performedPatterns: [HapticFeedbackPattern] = []

    public init() {}

    public func perform(_ pattern: HapticFeedbackPattern) {
        lock.lock()
        defer { lock.unlock() }
        performedPatterns.append(pattern)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        performedPatterns.removeAll()
    }
}
