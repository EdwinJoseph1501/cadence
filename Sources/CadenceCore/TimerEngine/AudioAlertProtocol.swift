import Foundation

/// Pure contract for playing audio completion alerts.
///
/// Decoupled from AppKit to ensure CadenceCore remains pure Swift.
public protocol AudioAlertProtocol: Sendable {
    func playCompletionAlert()
}

/// No-op audio alert player for previews and disabled audio states.
public struct NoOpAudioAlertPlayer: AudioAlertProtocol {
    public init() {}
    public func playCompletionAlert() {}
}

/// Mock audio alert player recording audio events for deterministic unit tests.
public final class MockAudioAlertPlayer: AudioAlertProtocol, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var playCount: Int = 0

    public init() {}

    public func playCompletionAlert() {
        lock.lock()
        defer { lock.unlock() }
        playCount += 1
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        playCount = 0
    }
}
