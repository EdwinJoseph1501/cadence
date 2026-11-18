import AppKit
import CadenceCore
import CadenceUI
import Foundation
import UserNotifications

/// Main application delegate coordinating system activation, Dock reopen, and notification interactions.
@MainActor
public final class CadenceAppDelegate: NSObject, NSApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        WindowLifecycleController.shared.restoreMainWindow()
        return true
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
    {
        WindowLifecycleController.shared.prepareForTermination()
        return .terminateNow
    }

    // MARK: - UNUserNotificationCenterDelegate

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            WindowLifecycleController.shared.restoreMainWindow()
        }
    }
}
