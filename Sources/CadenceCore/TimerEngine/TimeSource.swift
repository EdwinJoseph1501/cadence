import Foundation

/// Protocol abstracting the current wall-clock and monotonic time providers.
///
/// Enables complete, deterministic unit testing without waiting for real time intervals
/// or depending on the system clock.
public protocol TimeSourceProtocol: Sendable {
    var now: Date { get }
}

/// Default system time provider backed by `Date.now`.
public struct SystemTimeSource: TimeSourceProtocol {
    public init() {}

    public var now: Date {
        Date()
    }
}

/// Deterministic mock time provider for testing suspension, drift, and deadline evaluation.
public final class SimulatedTimeSource: TimeSourceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var currentTime: Date

    public init(initialTime: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.currentTime = initialTime
    }

    public var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return currentTime
    }

    public func setTime(_ date: Date) {
        lock.lock()
        currentTime = date
        lock.unlock()
    }

    public func advance(by interval: TimeInterval) {
        lock.lock()
        currentTime = currentTime.addingTimeInterval(interval)
        lock.unlock()
    }
}
