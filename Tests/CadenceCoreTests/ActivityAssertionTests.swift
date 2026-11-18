import Foundation
import Testing

@testable import CadenceCore

@Suite("Activity Assertion & Notification Contract Tests")
struct ActivityAssertionTests {
    @Test("MockActivityManager tracks begin and end lifecycle correctly")
    func testMockActivityManagerLifecycle() {
        let manager = MockActivityManager()
        #expect(manager.activeAssertionCount == 0)

        let token1 = manager.beginUserInitiatedActivity(reason: "Active Focus Session")
        #expect(token1 != nil)
        #expect(manager.activeAssertionCount == 1)
        #expect(manager.lastReason == "Active Focus Session")

        let token2 = manager.beginUserInitiatedActivity(reason: "Second Activity")
        #expect(token2 != nil)
        #expect(manager.activeAssertionCount == 2)

        manager.endActivity(token1)
        #expect(manager.activeAssertionCount == 1)

        manager.endActivity(token2)
        #expect(manager.activeAssertionCount == 0)

        // Ending with nil does not decrement
        manager.endActivity(nil)
        #expect(manager.activeAssertionCount == 0)
    }

    @Test("MockNotificationScheduler records scheduling and cancellation events")
    func testMockNotificationScheduler() async {
        let scheduler = MockNotificationScheduler(authorizationGranted: true)

        let granted = await scheduler.requestAuthorization()
        #expect(granted)
        let requested = await scheduler.authorizationRequested
        #expect(requested)

        await scheduler.scheduleNotification(
            title: "Cadence",
            body: "Focus session complete.",
            triggerIn: 300,
            identifier: "com.cadence.timer.completion"
        )
        let scheduled = await scheduler.scheduledNotifications
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.title == "Cadence")
        #expect(scheduled.first?.triggerIn == 300)

        await scheduler.cancelPendingNotifications(identifiers: ["com.cadence.timer.completion"])
        let cancelled = await scheduler.cancelledIdentifiers
        #expect(cancelled == ["com.cadence.timer.completion"])

        await scheduler.clear()
        let clearedScheduled = await scheduler.scheduledNotifications
        let clearedCancelled = await scheduler.cancelledIdentifiers
        let clearedRequested = await scheduler.authorizationRequested
        #expect(clearedScheduled.isEmpty)
        #expect(clearedCancelled.isEmpty)
        #expect(!clearedRequested)
    }

    @Test("MockNotificationScheduler records sound preference correctly")
    func testMockNotificationSchedulerSoundPreference() async {
        let scheduler = MockNotificationScheduler()

        await scheduler.scheduleNotification(
            title: "Cadence",
            body: "Audible complete.",
            triggerIn: 300,
            identifier: "id.sound.true",
            sound: true
        )
        await scheduler.scheduleNotification(
            title: "Cadence",
            body: "Silent complete.",
            triggerIn: 600,
            identifier: "id.sound.false",
            sound: false
        )

        let scheduled = await scheduler.scheduledNotifications
        #expect(scheduled.count == 2)
        #expect(scheduled[0].sound == true)
        #expect(scheduled[0].identifier == "id.sound.true")
        #expect(scheduled[1].sound == false)
        #expect(scheduled[1].identifier == "id.sound.false")
    }
}
