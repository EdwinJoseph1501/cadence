import Foundation

/// Contract for updating the macOS application Dock tile badge with live session status.
public protocol DockTileManagerProtocol: Sendable {
    func setBadge(_ label: String?)
}

/// No-op dock tile manager for headless environments, unit tests, and previews.
public final class NoOpDockTileManager: DockTileManagerProtocol, @unchecked Sendable {
    public init() {}
    public func setBadge(_ label: String?) {}
}

/// Mock dock tile manager for deterministic state verification.
public final class MockDockTileManager: DockTileManagerProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _badges: [String?] = []

    public init() {}

    public func setBadge(_ label: String?) {
        lock.lock()
        defer { lock.unlock() }
        _badges.append(label)
    }

    public var badges: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return _badges
    }

    public var lastBadge: String? {
        lock.lock()
        defer { lock.unlock() }
        return _badges.last ?? nil
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _badges.removeAll()
    }
}
