import Foundation

/// Contract for persisting and restoring timer state across application launches.
public protocol TimerPersistenceProtocol: Sendable {
    func save(session: PersistedTimerSession)
    func loadSession() -> PersistedTimerSession?
    func clearSession()
}

/// In-memory persistence implementation for deterministic testing and previews.
public final class InMemoryTimerPersistence: TimerPersistenceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var session: PersistedTimerSession?

    public init(initialSession: PersistedTimerSession? = nil) {
        self.session = initialSession
    }

    public func save(session: PersistedTimerSession) {
        lock.lock()
        defer { lock.unlock() }
        self.session = session
    }

    public func loadSession() -> PersistedTimerSession? {
        lock.lock()
        defer { lock.unlock() }
        return session
    }

    public func clearSession() {
        lock.lock()
        defer { lock.unlock() }
        self.session = nil
    }
}

/// Production persistence backed by UserDefaults.
public final class UserDefaultsTimerPersistence: TimerPersistenceProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()

    public init(
        suiteName: String? = nil,
        key: String = "com.cadence.timer.persisted_session"
    ) {
        if let suiteName, let customSuite = UserDefaults(suiteName: suiteName) {
            self.defaults = customSuite
        } else {
            self.defaults = .standard
        }
        self.key = key
    }

    public func save(session: PersistedTimerSession) {
        lock.lock()
        defer { lock.unlock() }
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: key)
        } catch {
            // Non-fatal serialization error
        }
    }

    public func loadSession() -> PersistedTimerSession? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(PersistedTimerSession.self, from: data)
        } catch {
            return nil
        }
    }

    public func clearSession() {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: key)
    }
}
