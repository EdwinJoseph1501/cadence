import CadenceCore
import Foundation
import UserNotifications

/// Production implementation of NotificationSchedulerProtocol using the native macOS UserNotifications framework.
public final class UNNotificationScheduler: NotificationSchedulerProtocol, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    public func scheduleNotification(
        title: String,
        body: String,
        triggerIn: TimeInterval,
        identifier: String,
        sound: Bool = true
    ) async {
        guard triggerIn > 0 else { return }

        let settings = await center.notificationSettings()
        guard
            settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        } else {
            content.sound = nil
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerIn, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Non-fatal scheduling failure
        }
    }

    public func cancelPendingNotifications(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
