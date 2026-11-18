import CadenceCore
import CadenceUI
import Foundation
import Testing

@Suite("TimerStore State Management Tests")
@MainActor
struct TimerStoreTests {
    @Test("Initialization defaults match specification")
    func testInitializationDefaults() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)

        #expect(store.phase == .idle)
        #expect(store.selectedPreset == .focus)
        #expect(store.activeDuration == 1500)
        #expect(store.remainingDuration() == 1500)
        #expect(store.progressFraction() == 0.0)
        #expect(store.formattedCountdown() == "25:00")
    }

    @Test("Custom default preset on initialization")
    func testCustomDefaultPresetInitialization() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .quick)

        #expect(store.phase == .idle)
        #expect(store.selectedPreset == .quick)
        #expect(store.activeDuration == 300)
        #expect(store.remainingDuration() == 300)
        #expect(store.formattedCountdown() == "05:00")
    }

    @Test("Start transitions to running phase with deadline anchored to clock")
    func testStartTransition() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.start()

        #expect(store.phase.isRunning)
        if case .running(let deadline, let total) = store.phase {
            #expect(total == 1500)
            #expect(deadline == Date(timeIntervalSince1970: 11_500))
        } else {
            Issue.record("Expected phase to be .running")
        }

        #expect(store.remainingDuration() == 1500)
        #expect(store.progressFraction() == 0.0)
    }

    @Test("Pause preserves remaining duration without clock drift")
    func testPausePreservesDuration() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .quick)

        store.start()
        clock.advance(by: 100)

        store.pause()

        #expect(store.phase.isPaused)
        if case .paused(let remaining, let total) = store.phase {
            #expect(remaining == 200)
            #expect(total == 300)
        } else {
            Issue.record("Expected phase to be .paused")
        }

        #expect(store.remainingDuration() == 200)
        #expect(abs(store.progressFraction() - (100.0 / 300.0)) < 0.001)

        // Advancing clock while paused must not decrease remaining duration
        clock.advance(by: 3600)
        #expect(store.remainingDuration() == 200)
    }

    @Test("Resume recalculates target deadline from current time anchor")
    func testResumeRecalculatesDeadline() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .quick)

        store.start()
        clock.advance(by: 120)
        store.pause()

        // Suspension during pause (e.g. 5 minutes)
        clock.advance(by: 300)

        store.resume()
        #expect(store.phase.isRunning)

        if case .running(let deadline, let total) = store.phase {
            #expect(total == 300)
            #expect(deadline.timeIntervalSince(clock.now) == 180)
        } else {
            Issue.record("Expected phase to be .running")
        }

        #expect(store.remainingDuration() == 180)
    }

    @Test("Reset transitions back to idle")
    func testReset() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .deepWork)

        store.start()
        clock.advance(by: 500)
        store.reset()

        #expect(store.phase == .idle)
        #expect(store.selectedPreset == .deepWork)
        #expect(store.activeDuration == 3000)
        #expect(store.remainingDuration() == 3000)
        #expect(store.progressFraction() == 0.0)
        #expect(store.formattedCountdown() == "50:00")
    }

    @Test("Toggle handles idle, running, paused, and completed transitions")
    func testToggleLifecycle() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .quick)

        // 1. Idle -> Toggle starts timer
        #expect(store.phase == .idle)
        store.toggle()
        #expect(store.phase.isRunning)

        // 2. Running -> Toggle pauses timer
        clock.advance(by: 60)
        store.toggle()
        #expect(store.phase.isPaused)
        #expect(store.remainingDuration() == 240)

        // 3. Paused -> Toggle resumes timer
        clock.advance(by: 10)
        store.toggle()
        #expect(store.phase.isRunning)
        #expect(store.remainingDuration() == 240)

        // 4. Running -> Deadline expires -> Completed -> Toggle restarts timer
        clock.advance(by: 250)
        store.evaluateDeadline()
        #expect(store.phase.isCompleted)

        store.toggle()
        #expect(store.phase.isRunning)
        #expect(store.remainingDuration() == 300)
    }

    @Test("Preset switching updates active duration and returns to idle")
    func testPresetSwitching() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.selectPreset(.quick)
        #expect(store.selectedPreset == .quick)
        #expect(store.activeDuration == 300)
        #expect(store.phase == .idle)

        store.selectPreset(.deepWork)
        #expect(store.selectedPreset == .deepWork)
        #expect(store.activeDuration == 3000)

        store.selectPreset(.longSession)
        #expect(store.selectedPreset == .longSession)
        #expect(store.activeDuration == 5400)

        // Running timer ignores preset switches
        store.start()
        store.selectPreset(.quick)
        #expect(store.selectedPreset == .longSession)
        #expect(store.phase.isRunning)
    }

    @Test("Custom duration validation rejects invalid values and accepts valid range")
    func testCustomDurationValidation() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)

        // Invalid: 0, negative, > 86400 (24h)
        #expect(!store.setCustomDuration(0))
        #expect(!store.setCustomDuration(-100))
        #expect(!store.setCustomDuration(86_401))
        #expect(store.selectedPreset == .focus)

        // Valid boundaries: 1s, 86400s, 3600s
        #expect(store.setCustomDuration(1))
        #expect(store.selectedPreset == .custom)
        #expect(store.activeDuration == 1)
        #expect(store.phase == .idle)
        #expect(store.formattedCountdown() == "00:01")

        #expect(store.setCustomDuration(86_400))
        #expect(store.activeDuration == 86_400)
        #expect(store.formattedCountdown() == "24:00:00")

        #expect(store.setCustomDuration(3600))
        #expect(store.activeDuration == 3600)
        #expect(store.formattedCountdown() == "01:00:00")
    }

    @Test("Evaluate deadline marks completed when clock exceeds deadline")
    func testEvaluateDeadlineCompletion() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)
        store.setCustomDuration(10)

        store.start()
        #expect(store.phase.isRunning)

        clock.advance(by: 5)
        store.evaluateDeadline()
        #expect(store.phase.isRunning)
        #expect(store.remainingDuration() == 5)
        #expect(store.progressFraction() == 0.5)

        clock.advance(by: 5)
        store.evaluateDeadline()
        #expect(store.phase.isCompleted)
        #expect(store.remainingDuration() == 0)
        #expect(store.progressFraction() == 1.0)
        #expect(store.formattedCountdown() == "00:00")
    }

    @Test("Rapid start, pause, resume, and reset cycles maintain valid state")
    func testRapidToggleAndResetCycles() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        for _ in 0..<20 {
            store.toggle()  // idle -> running
            #expect(store.phase.isRunning)
            clock.advance(by: 1)

            store.toggle()  // running -> paused
            #expect(store.phase.isPaused)

            store.toggle()  // paused -> running
            #expect(store.phase.isRunning)

            store.reset()  // running -> idle
            #expect(store.phase == .idle)
            #expect(store.remainingDuration() == 1500)
        }
    }

    @Test("All presets remain rejected while timer is actively running")
    func testAllPresetsRejectedWhileRunning() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.start()
        #expect(store.phase.isRunning)

        for preset in TimerPreset.allCases {
            store.selectPreset(preset)
            #expect(store.selectedPreset == .focus)
            #expect(store.activeDuration == 1500)
            #expect(store.phase.isRunning)
        }
    }

    @Test("Strict boundary validation for custom durations")
    func testStrictBoundaryCustomDurations() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)

        #expect(!store.setCustomDuration(-0.001))
        #expect(!store.setCustomDuration(-100.0))
        #expect(!store.setCustomDuration(0.0))
        #expect(!store.setCustomDuration(86_400.001))
        #expect(!store.setCustomDuration(100_000.0))

        #expect(store.setCustomDuration(0.5))
        #expect(store.activeDuration == 0.5)

        #expect(store.setCustomDuration(86_400))
        #expect(store.activeDuration == 86_400)
    }

    // MARK: - Phase 3 Reliability, Native Lifecycle & Persistence Tests

    @Test("Sleep/wake recovery past deadline immediately marks completed")
    func testSleepWakeRecoveryPastDeadline() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let activityManager = MockActivityManager()
        let store = TimerStore(
            timeSource: clock,
            activityManager: activityManager,
            defaultPreset: .quick
        )

        store.start()
        #expect(store.phase.isRunning)
        #expect(activityManager.activeAssertionCount == 1)

        // System sleeps for 600s (past 300s deadline)
        clock.advance(by: 600)

        // System wakes and notifies store
        store.handleSystemWake()

        #expect(store.phase.isCompleted)
        #expect(store.remainingDuration() == 0)
        #expect(store.progressFraction() == 1.0)
        #expect(store.formattedCountdown() == "00:00")
        #expect(activityManager.activeAssertionCount == 0)
    }

    @Test("Sleep/wake recovery before deadline preserves exact remaining time without drift")
    func testSleepWakeRecoveryBeforeDeadline() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.start()
        #expect(store.remainingDuration() == 1500)

        // System sleeps for 350 seconds
        clock.advance(by: 350)
        store.handleSystemWake()

        #expect(store.phase.isRunning)
        #expect(store.remainingDuration() == 1150)
        #expect(store.formattedCountdown() == "19:10")
    }

    @Test("Relaunch recovery restores running countdown without resetting to full duration")
    func testRelaunchRecoveryActiveSession() {
        let initialTime = Date(timeIntervalSince1970: 10_000)
        let clock = SimulatedTimeSource(initialTime: initialTime)
        let persistence = InMemoryTimerPersistence()
        let activityManager = MockActivityManager()

        // 1. Session was running with 200 seconds remaining out of 300
        let deadline = initialTime.addingTimeInterval(200)
        let session = PersistedTimerSession(
            phase: .running(targetDeadline: deadline, totalDuration: 300),
            selectedPreset: .quick,
            activeDuration: 300,
            savedAt: initialTime
        )
        persistence.save(session: session)

        // 2. App relaunches
        let store = TimerStore(
            timeSource: clock,
            persistence: persistence,
            activityManager: activityManager
        )

        #expect(store.phase.isRunning)
        #expect(store.selectedPreset == .quick)
        #expect(store.activeDuration == 300)
        #expect(store.remainingDuration() == 200)
        #expect(store.formattedCountdown() == "03:20")
        #expect(activityManager.activeAssertionCount == 1)
    }

    @Test(
        "Relaunch recovery transitions directly to completed if deadline elapsed while terminated")
    func testRelaunchRecoveryExpiredSession() {
        let launchTime = Date(timeIntervalSince1970: 20_000)
        let clock = SimulatedTimeSource(initialTime: launchTime)
        let persistence = InMemoryTimerPersistence()
        let activityManager = MockActivityManager()

        // Session deadline was at 10_300, but app launches at 20_000
        let pastDeadline = Date(timeIntervalSince1970: 10_300)
        let session = PersistedTimerSession(
            phase: .running(targetDeadline: pastDeadline, totalDuration: 300),
            selectedPreset: .quick,
            activeDuration: 300,
            savedAt: Date(timeIntervalSince1970: 10_000)
        )
        persistence.save(session: session)

        let store = TimerStore(
            timeSource: clock,
            persistence: persistence,
            activityManager: activityManager
        )

        #expect(store.phase.isCompleted)
        #expect(store.remainingDuration() == 0)
        #expect(store.formattedCountdown() == "00:00")
        #expect(activityManager.activeAssertionCount == 0)
    }

    @Test("Relaunch recovery preserves paused remaining duration regardless of elapsed wall time")
    func testRelaunchRecoveryPausedSession() {
        let launchTime = Date(timeIntervalSince1970: 50_000)
        let clock = SimulatedTimeSource(initialTime: launchTime)
        let persistence = InMemoryTimerPersistence()

        let session = PersistedTimerSession(
            phase: .paused(remainingDuration: 142, totalDuration: 300),
            selectedPreset: .quick,
            activeDuration: 300,
            savedAt: Date(timeIntervalSince1970: 10_000)
        )
        persistence.save(session: session)

        let store = TimerStore(timeSource: clock, persistence: persistence)

        #expect(store.phase.isPaused)
        #expect(store.remainingDuration() == 142)
        #expect(store.formattedCountdown() == "02:22")
    }

    @Test("Relaunch restores last-used duration and preset")
    func testRelaunchRestoresLastUsedDuration() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let persistence = InMemoryTimerPersistence()

        let session = PersistedTimerSession(
            phase: .idle,
            selectedPreset: .custom,
            activeDuration: 7200,
            savedAt: clock.now
        )
        persistence.save(session: session)

        let store = TimerStore(timeSource: clock, persistence: persistence)

        #expect(store.phase == .idle)
        #expect(store.selectedPreset == .custom)
        #expect(store.activeDuration == 7200)
        #expect(store.remainingDuration() == 7200)
        #expect(store.formattedCountdown() == "02:00:00")
    }

    @Test("App Nap activity assertion lifecycle holds strictly while running")
    func testAppNapActivityAssertionLifecycle() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let activityManager = MockActivityManager()
        let store = TimerStore(
            timeSource: clock,
            activityManager: activityManager,
            defaultPreset: .quick
        )

        #expect(activityManager.activeAssertionCount == 0)

        // 1. Start -> asserts activity
        store.start()
        #expect(activityManager.activeAssertionCount == 1)

        // 2. Pause -> releases assertion
        store.pause()
        #expect(activityManager.activeAssertionCount == 0)

        // 3. Resume -> re-asserts activity
        store.resume()
        #expect(activityManager.activeAssertionCount == 1)

        // 4. Complete -> releases assertion
        clock.advance(by: 300)
        store.evaluateDeadline()
        #expect(store.phase.isCompleted)
        #expect(activityManager.activeAssertionCount == 0)

        // 5. Restart then reset -> releases assertion
        store.start()
        #expect(activityManager.activeAssertionCount == 1)
        store.reset()
        #expect(activityManager.activeAssertionCount == 0)
    }

    @Test("Notification scheduling and cancellation lifecycle")
    func testNotificationLifecycle() async {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let scheduler = MockNotificationScheduler()
        let store = TimerStore(
            timeSource: clock,
            notificationScheduler: scheduler,
            defaultPreset: .quick
        )

        // Start timer -> requests permission and schedules notification
        store.start()
        await store.waitForNotificationTasks()

        let requested = await scheduler.authorizationRequested
        #expect(requested)

        let scheduled = await scheduler.scheduledNotifications
        #expect(!scheduled.isEmpty)
        #expect(scheduled.first?.triggerIn == 300)
        #expect(scheduled.first?.identifier == "com.cadence.timer.completion")

        // Pause timer -> cancels pending notifications
        store.pause()
        await store.waitForNotificationTasks()

        let cancelled = await scheduler.cancelledIdentifiers
        #expect(cancelled.contains("com.cadence.timer.completion"))
    }

    @Test("Notification scheduling reflects audio alert preference")
    func testNotificationSchedulingAudioPreference() async {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let scheduler = MockNotificationScheduler()
        let store = TimerStore(
            timeSource: clock,
            notificationScheduler: scheduler,
            defaultPreset: .quick
        )

        // Default: audio enabled -> notification scheduled with sound = true
        store.start()
        await store.waitForNotificationTasks()

        var scheduled = await scheduler.scheduledNotifications
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.sound == true)

        // Toggle audio alert while running -> reschedules notification with sound = false
        store.toggleAudioAlert()
        await store.waitForNotificationTasks()

        scheduled = await scheduler.scheduledNotifications
        #expect(scheduled.count == 2)
        #expect(scheduled.last?.sound == false)

        // Toggle back while running -> reschedules notification with sound = true
        store.toggleAudioAlert()
        await store.waitForNotificationTasks()

        scheduled = await scheduler.scheduledNotifications
        #expect(scheduled.count == 3)
        #expect(scheduled.last?.sound == true)
    }

    @Test("Exactly-once completion semantics prevent duplicate triggers")
    func testExactlyOnceCompletionHandling() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let activityManager = MockActivityManager()
        let store = TimerStore(
            timeSource: clock,
            activityManager: activityManager,
            defaultPreset: .quick
        )

        store.start()
        #expect(activityManager.activeAssertionCount == 1)

        clock.advance(by: 300)
        store.evaluateDeadline()
        #expect(store.phase.isCompleted)
        #expect(activityManager.activeAssertionCount == 0)

        // Redundant evaluation calls must be no-ops
        for _ in 0..<10 {
            clock.advance(by: 10)
            store.evaluateDeadline()
            store.handleSystemWake()
            #expect(store.phase.isCompleted)
            #expect(activityManager.activeAssertionCount == 0)
        }
    }

    // MARK: - Phase 4 Audio Alerts & Interaction Polish Tests

    @Test("Audio alert fires exactly once on timer completion")
    func testAudioAlertFiresExactlyOnceOnCompletion() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let player = MockAudioAlertPlayer()
        let store = TimerStore(
            timeSource: clock,
            audioAlertPlayer: player,
            defaultPreset: .quick
        )

        store.start()
        #expect(player.playCount == 0)

        // Advance to deadline
        clock.advance(by: 300)
        store.evaluateDeadline()

        #expect(store.phase.isCompleted)
        #expect(player.playCount == 1)

        // Multiple subsequent wake or deadline evaluations must not repeat audio
        for _ in 0..<5 {
            store.evaluateDeadline()
            store.handleSystemWake()
            #expect(player.playCount == 1)
        }
    }

    @Test("Audio alert does not fire when audio is disabled")
    func testAudioAlertDisabledDoesNotPlay() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let player = MockAudioAlertPlayer()
        let store = TimerStore(
            timeSource: clock,
            audioAlertPlayer: player,
            defaultPreset: .quick
        )

        store.setAudioAlertEnabled(false)
        #expect(!store.isAudioAlertEnabled)

        store.start()
        clock.advance(by: 300)
        store.evaluateDeadline()

        #expect(store.phase.isCompleted)
        #expect(player.playCount == 0)
    }

    @Test("Audio alert toggle persists preference across store instances")
    func testAudioAlertTogglePersistsPreference() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let persistence = InMemoryTimerPersistence()
        let store1 = TimerStore(timeSource: clock, persistence: persistence)

        #expect(store1.isAudioAlertEnabled == true)

        store1.toggleAudioAlert()
        #expect(store1.isAudioAlertEnabled == false)

        // Restore in a fresh store instance
        let store2 = TimerStore(timeSource: clock, persistence: persistence)
        #expect(store2.isAudioAlertEnabled == false)

        store2.toggleAudioAlert()
        #expect(store2.isAudioAlertEnabled == true)
    }

    @Test("Expired session relaunch does not trigger audio alert")
    func testExpiredSessionRelaunchDoesNotTriggerAudio() {
        let launchTime = Date(timeIntervalSince1970: 20_000)
        let clock = SimulatedTimeSource(initialTime: launchTime)
        let persistence = InMemoryTimerPersistence()
        let player = MockAudioAlertPlayer()

        // Session deadline passed 9,700s ago while app was closed
        let pastDeadline = Date(timeIntervalSince1970: 10_300)
        let session = PersistedTimerSession(
            phase: .running(targetDeadline: pastDeadline, totalDuration: 300),
            selectedPreset: .quick,
            activeDuration: 300,
            isAudioAlertEnabled: true,
            savedAt: Date(timeIntervalSince1970: 10_000)
        )
        persistence.save(session: session)

        let store = TimerStore(
            timeSource: clock,
            persistence: persistence,
            audioAlertPlayer: player
        )

        #expect(store.phase.isCompleted)
        #expect(player.playCount == 0)
    }

    @Test("Custom sheet presentation state can be managed")
    func testCustomSheetPresentationState() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)

        #expect(store.isCustomSheetPresented == false)
        store.isCustomSheetPresented = true
        #expect(store.isCustomSheetPresented == true)
        store.isCustomSheetPresented = false
        #expect(store.isCustomSheetPresented == false)
    }

    // MARK: - Phase 6B Stress & Reliability Tests

    @Test("50 consecutive pause and resume cycles accumulate zero timing drift")
    func testConsecutivePauseAndResumeZeroDrift() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.start()
        var expectedRemaining: TimeInterval = 1500

        for _ in 0..<50 {
            clock.advance(by: 5.5)
            expectedRemaining -= 5.5
            store.pause()
            #expect(store.phase.isPaused)
            #expect(abs(store.remainingDuration() - expectedRemaining) < 0.0001)

            // Advance clock while paused
            clock.advance(by: 120.0)
            #expect(abs(store.remainingDuration() - expectedRemaining) < 0.0001)

            store.resume()
            #expect(store.phase.isRunning)
            #expect(abs(store.remainingDuration() - expectedRemaining) < 0.0001)
        }

        #expect(abs(store.remainingDuration() - (1500 - (50 * 5.5))) < 0.0001)
    }

    @Test("Midnight and New Year boundary transitions preserve monotonic countdown accuracy")
    func testMidnightAndNewYearBoundaryTransitions() {
        // 2026-12-31 23:55:00 UTC (10 minutes focus timer, crossing midnight into 2027)
        let newYearsEve = Date(timeIntervalSince1970: 1_798_761_300)
        let clock = SimulatedTimeSource(initialTime: newYearsEve)
        let store = TimerStore(timeSource: clock)
        _ = store.setCustomDuration(600)

        store.start()
        #expect(store.remainingDuration() == 600)

        // Advance 5 minutes to 2027-01-01 00:00:00 UTC
        clock.advance(by: 300)
        #expect(store.remainingDuration() == 300)
        #expect(store.formattedCountdown() == "05:00")

        // Advance another 2 minutes into 2027
        clock.advance(by: 120)
        #expect(store.remainingDuration() == 180)
        #expect(store.formattedCountdown() == "03:00")

        // Complete the timer
        clock.advance(by: 180)
        store.evaluateDeadline()
        #expect(store.phase.isCompleted)
        #expect(store.remainingDuration() == 0)
    }

    @Test("Extended simulated 12-hour sleep while running completes immediately on wake")
    func testExtended12HourSleepWhileRunning() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let activityManager = MockActivityManager()
        let audioPlayer = MockAudioAlertPlayer()
        let store = TimerStore(
            timeSource: clock,
            activityManager: activityManager,
            audioAlertPlayer: audioPlayer,
            defaultPreset: .focus
        )

        store.start()
        #expect(store.phase.isRunning)
        #expect(activityManager.activeAssertionCount == 1)

        // System undergoes deep sleep for 12 hours (43,200 seconds)
        clock.advance(by: 43_200)

        // System wake event
        store.handleSystemWake()

        #expect(store.phase.isCompleted)
        #expect(store.remainingDuration() == 0)
        #expect(store.progressFraction() == 1.0)
        #expect(store.formattedCountdown() == "00:00")
        #expect(activityManager.activeAssertionCount == 0)
        #expect(audioPlayer.playCount == 1)

        // Redundant wake events must not re-trigger completion or audio chime
        store.handleSystemWake()
        #expect(audioPlayer.playCount == 1)
    }

    @Test("Extended simulated 8-hour sleep while paused preserves remaining duration completely")
    func testExtended8HourSleepWhilePaused() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock, defaultPreset: .focus)

        store.start()
        clock.advance(by: 300)
        store.pause()
        #expect(store.remainingDuration() == 1200)

        // System sleeps for 8 hours (28,800s)
        clock.advance(by: 28_800)
        store.handleSystemWake()

        #expect(store.phase.isPaused)
        #expect(store.remainingDuration() == 1200)
        #expect(store.formattedCountdown() == "20:00")

        // Resuming after 8 hours sleep proceeds cleanly
        store.resume()
        #expect(store.phase.isRunning)
        clock.advance(by: 100)
        #expect(store.remainingDuration() == 1100)
    }

    @Test("Audio preference change while running immediately updates notification sound")
    func testAudioPreferenceChangeWhileRunning() async {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let notificationScheduler = MockNotificationScheduler()
        let store = TimerStore(
            timeSource: clock,
            notificationScheduler: notificationScheduler,
            defaultPreset: .quick
        )

        store.start()
        await store.waitForNotificationTasks()
        var scheduled = await notificationScheduler.scheduledNotifications
        #expect(scheduled.last?.sound == true)

        // Toggle audio off while running
        store.toggleAudioAlert()
        await store.waitForNotificationTasks()
        #expect(store.isAudioAlertEnabled == false)
        scheduled = await notificationScheduler.scheduledNotifications
        #expect(scheduled.last?.sound == false)

        // Toggle audio back on while running
        store.toggleAudioAlert()
        await store.waitForNotificationTasks()
        #expect(store.isAudioAlertEnabled == true)
        scheduled = await notificationScheduler.scheduledNotifications
        #expect(scheduled.last?.sound == true)
    }

    @Test("Extreme custom duration boundary limits")
    func testExtremeCustomDurationLimits() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10_000))
        let store = TimerStore(timeSource: clock)

        // 1 second (minimum integer focus)
        #expect(store.setCustomDuration(1.0))
        #expect(store.activeDuration == 1.0)
        #expect(store.formattedCountdown() == "00:01")

        // 86,400 seconds (24 hours maximum)
        #expect(store.setCustomDuration(86_400.0))
        #expect(store.activeDuration == 86_400.0)
        #expect(store.formattedCountdown() == "24:00:00")

        // Exceeding maximum
        #expect(!store.setCustomDuration(86_400.01))
        #expect(!store.setCustomDuration(100_000.0))
        #expect(store.activeDuration == 86_400.0)

        // Zero or negative
        #expect(!store.setCustomDuration(0.0))
        #expect(!store.setCustomDuration(-1.0))
        #expect(store.activeDuration == 86_400.0)
    }
}
