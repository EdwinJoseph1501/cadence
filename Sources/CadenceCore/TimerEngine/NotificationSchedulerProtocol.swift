import Foundation

/// Pure contract for scheduling and cancelling timer completion notifications.
///
/// Decoupled from UserNotifications to ensure CadenceCore remains pure Swift.
public protocol NotificationSchedulerProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func scheduleNotification(
        title: String,
        body: String,
        triggerIn: TimeInterval,
        identifier: String,
        sound: Bool
    ) async
    func cancelPendingNotifications(identifiers: [String]) async
}

extension NotificationSchedulerProtocol {
    public func scheduleNotification(
        title: String,
        body: String,
        triggerIn: TimeInterval,
        identifier: String
    ) async {
        await scheduleNotification(
            title: title,
            body: body,
            triggerIn: triggerIn,
            identifier: identifier,
            sound: true
        )
    }
}

/// No-op scheduler for default previews and disabled states.
public struct NoOpNotificationScheduler: NotificationSchedulerProtocol {
    public init() {}
    public func requestAuthorization() async -> Bool { false }
    public func scheduleNotification(
        title: String,
        body: String,
        triggerIn: TimeInterval,
        identifier: String,
        sound: Bool
    ) async {}
    public func cancelPendingNotifications(identifiers: [String]) async {}
}

/// Mock scheduler recording events for deterministic unit tests.
public actor MockNotificationScheduler: NotificationSchedulerProtocol {
    public struct ScheduledNotification: Sendable, Equatable {
        public let title: String
        public let body: String
        public let triggerIn: TimeInterval
        public let identifier: String
        public let sound: Bool

        public init(
            title: String,
            body: String,
            triggerIn: TimeInterval,
            identifier: String,
            sound: Bool = true
        ) {
            self.title = title
            self.body = body
            self.triggerIn = triggerIn
            self.identifier = identifier
            self.sound = sound
        }
    }

    public var authorizationGranted: Bool = true
    public private(set) var authorizationRequested: Bool = false
    public private(set) var scheduledNotifications: [ScheduledNotification] = []
    public private(set) var cancelledIdentifiers: [String] = []

    public init(authorizationGranted: Bool = true) {
        self.authorizationGranted = authorizationGranted
    }

    public func setAuthorizationGranted(_ granted: Bool) {
        self.authorizationGranted = granted
    }

    public func requestAuthorization() async -> Bool {
        authorizationRequested = true
        return authorizationGranted
    }

    public func scheduleNotification(
        title: String,
        body: String,
        triggerIn: TimeInterval,
        identifier: String,
        sound: Bool
    ) async {
        scheduledNotifications.append(
            ScheduledNotification(
                title: title,
                body: body,
                triggerIn: triggerIn,
                identifier: identifier,
                sound: sound
            )
        )
    }

    public func cancelPendingNotifications(identifiers: [String]) async {
        cancelledIdentifiers.append(contentsOf: identifiers)
    }

    public func clear() {
        scheduledNotifications.removeAll()
        cancelledIdentifiers.removeAll()
        authorizationRequested = false
    }
}
