import Foundation

/// Pure contract for managing process activity assertions to prevent App Nap throttling during active countdowns.
public protocol ActivityAssertionProtocol: Sendable {
    func beginUserInitiatedActivity(reason: String) -> (any Sendable)?
    func endActivity(_ token: (any Sendable)?)
}

/// No-op manager for previews and tests.
public struct NoOpActivityManager: ActivityAssertionProtocol {
    public init() {}
    public func beginUserInitiatedActivity(reason: String) -> (any Sendable)? { nil }
    public func endActivity(_ token: (any Sendable)?) {}
}

/// Mock manager tracking activity assertions in unit tests.
public final class MockActivityManager: ActivityAssertionProtocol, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var activeAssertionCount: Int = 0
    public private(set) var lastReason: String?

    public init() {}

    public func beginUserInitiatedActivity(reason: String) -> (any Sendable)? {
        lock.lock()
        defer { lock.unlock() }
        activeAssertionCount += 1
        lastReason = reason
        return UUID().uuidString
    }

    public func endActivity(_ token: (any Sendable)?) {
        guard token != nil else { return }
        lock.lock()
        defer { lock.unlock() }
        activeAssertionCount = max(0, activeAssertionCount - 1)
    }
}

/// Sendable wrapper around Foundation's NSObjectProtocol activity token.
private final class ProcessActivityToken: @unchecked Sendable {
    let raw: any NSObjectProtocol
    init(raw: any NSObjectProtocol) {
        self.raw = raw
    }
}

/// Production implementation using ProcessInfo.processInfo.beginActivity.
public final class ProcessInfoActivityManager: ActivityAssertionProtocol, @unchecked Sendable {
    public init() {}

    public func beginUserInitiatedActivity(reason: String) -> (any Sendable)? {
        let token = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: reason
        )
        return ProcessActivityToken(raw: token)
    }

    public func endActivity(_ token: (any Sendable)?) {
        guard let token = token as? ProcessActivityToken else { return }
        ProcessInfo.processInfo.endActivity(token.raw)
    }
}
