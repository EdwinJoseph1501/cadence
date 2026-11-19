import CadenceCore
import Foundation
import Observation

/// Main-actor observable runtime state store coordinating timer lifecycle, persistence, audio alerts, and presentation models.
@Observable
@MainActor
public final class TimerStore {
    public private(set) var phase: TimerPhase = .idle
    public private(set) var selectedPreset: TimerPreset = .focus
    public private(set) var activeDuration: TimeInterval = TimerPreset.focus.defaultDuration
    public private(set) var isAudioAlertEnabled: Bool = true
    public private(set) var isAlwaysOnTop: Bool = false
    public var isCustomSheetPresented: Bool = false

    private let timeSource: any TimeSourceProtocol
    private let persistence: any TimerPersistenceProtocol
    private let notificationScheduler: any NotificationSchedulerProtocol
    private let activityManager: any ActivityAssertionProtocol
    private let audioAlertPlayer: any AudioAlertProtocol
    private let dockTileManager: any DockTileManagerProtocol

    private var activityToken: (any Sendable)?
    private var hasRequestedNotificationPermission: Bool = false
    private var notificationTask: Task<Void, Never>?
    private static let completionNotificationIdentifier = "com.cadence.timer.completion"

    public init(
        timeSource: any TimeSourceProtocol = SystemTimeSource(),
        persistence: any TimerPersistenceProtocol = InMemoryTimerPersistence(),
        notificationScheduler: any NotificationSchedulerProtocol = NoOpNotificationScheduler(),
        activityManager: any ActivityAssertionProtocol = ProcessInfoActivityManager(),
        audioAlertPlayer: any AudioAlertProtocol = NoOpAudioAlertPlayer(),
        dockTileManager: any DockTileManagerProtocol = NoOpDockTileManager(),
        defaultPreset: TimerPreset = .focus
    ) {
        self.timeSource = timeSource
        self.persistence = persistence
        self.notificationScheduler = notificationScheduler
        self.activityManager = activityManager
        self.audioAlertPlayer = audioAlertPlayer
        self.dockTileManager = dockTileManager

        if let restored = persistence.loadSession() {
            self.selectedPreset = restored.selectedPreset
            self.activeDuration = min(max(restored.activeDuration, 1), 86_400)
            self.isAudioAlertEnabled = restored.isAudioAlertEnabled
            self.isAlwaysOnTop = restored.isAlwaysOnTop

            switch restored.phase {
                case .idle:
                    self.phase = .idle
                case .running(let deadline, let total):
                    if timeSource.now < deadline {
                        self.phase = .running(targetDeadline: deadline, totalDuration: total)
                        self.activityToken = activityManager.beginUserInitiatedActivity(
                            reason: "Restored active countdown session"
                        )
                        let remaining = deadline.timeIntervalSince(timeSource.now)
                        let scheduler = notificationScheduler
                        let sound = isAudioAlertEnabled
                        self.notificationTask = Task {
                            await scheduler.scheduleNotification(
                                title: "Cadence",
                                body: "Focus session complete.",
                                triggerIn: remaining,
                                identifier: Self.completionNotificationIdentifier,
                                sound: sound
                            )
                        }
                    } else {
                        self.phase = .completed(completedAt: deadline, totalDuration: total)
                        self.activityToken = nil
                    }
                case .paused(let remaining, let total):
                    self.phase = .paused(remainingDuration: max(0, remaining), totalDuration: total)
                case .completed(let completedAt, let total):
                    self.phase = .completed(completedAt: completedAt, totalDuration: total)
            }
        } else {
            self.selectedPreset = defaultPreset
            self.activeDuration = defaultPreset.defaultDuration
            self.phase = .idle
        }

        saveSession()
        updateDockBadge()
    }

    isolated deinit {
        activityManager.endActivity(activityToken)
    }

    /// Starts a countdown from the currently active duration.
    public func start() {
        phase = TimerEngineCalculations.start(duration: activeDuration, from: timeSource.now)
        if case .running(let deadline, _) = phase {
            if activityToken == nil {
                activityToken = activityManager.beginUserInitiatedActivity(
                    reason: "Active countdown session"
                )
            }
            scheduleCompletionNotification(deadline: deadline)
        }
        saveSession()
        updateDockBadge()
    }

    /// Pauses an active countdown, locking in remaining duration.
    public func pause() {
        phase = TimerEngineCalculations.pause(currentPhase: phase, at: timeSource.now)
        if let token = activityToken {
            activityManager.endActivity(token)
            activityToken = nil
        }
        cancelCompletionNotification()
        saveSession()
        updateDockBadge()
    }

    /// Resumes a paused countdown from the current monotonic clock anchor.
    public func resume() {
        phase = TimerEngineCalculations.resume(currentPhase: phase, at: timeSource.now)
        if case .running(let deadline, _) = phase {
            if activityToken == nil {
                activityToken = activityManager.beginUserInitiatedActivity(
                    reason: "Active countdown session"
                )
            }
            scheduleCompletionNotification(deadline: deadline)
        }
        saveSession()
        updateDockBadge()
    }

    /// Resets the timer back to idle state without modifying the active preset or duration.
    public func reset() {
        phase = .idle
        if let token = activityToken {
            activityManager.endActivity(token)
            activityToken = nil
        }
        cancelCompletionNotification()
        saveSession()
        updateDockBadge()
    }

    /// Toggles the timer state: starts if idle, resumes if paused, pauses if running, restarts if completed.
    public func toggle() {
        switch phase {
            case .idle:
                start()
            case .running:
                pause()
            case .paused:
                resume()
            case .completed:
                start()
        }
    }

    /// Changes the current session without resetting elapsed progress. Returns false when the
    /// session is inactive, expired, or the resulting duration would leave the 1s...24h range.
    @discardableResult
    public func adjustDuration(by seconds: TimeInterval) -> Bool {
        guard seconds.isFinite, seconds != 0 else { return false }
        let now = timeSource.now
        let remaining: TimeInterval
        let total: TimeInterval
        switch phase {
            case .running(let deadline, let duration):
                remaining = deadline.timeIntervalSince(now)
                total = duration
            case .paused(let duration, let original):
                remaining = duration
                total = original
            case .idle, .completed:
                return false
        }

        let adjustedRemaining = remaining + seconds
        let adjustedTotal = total + seconds
        guard remaining > 0, adjustedRemaining >= 1, adjustedTotal >= 1,
            adjustedTotal <= 86_400
        else { return false }

        if phase.isRunning {
            let deadline = now.addingTimeInterval(adjustedRemaining)
            phase = .running(targetDeadline: deadline, totalDuration: adjustedTotal)
            scheduleCompletionNotification(deadline: deadline)
        } else {
            phase = .paused(
                remainingDuration: adjustedRemaining,
                totalDuration: adjustedTotal
            )
        }
        saveSession()
        updateDockBadge(at: now)
        return true
    }

    /// Indicates whether an adjustment can be applied at the current clock instant.
    public func canAdjustDuration(by seconds: TimeInterval) -> Bool {
        guard seconds.isFinite, seconds != 0 else { return false }
        let remaining = remainingDuration()
        let total: TimeInterval
        switch phase {
            case .running(_, let duration), .paused(_, let duration):
                total = duration
            case .idle, .completed:
                return false
        }
        return remaining > 0 && remaining + seconds >= 1
            && total + seconds >= 1 && total + seconds <= 86_400
    }

    /// The expected end time, assuming a paused session resumes now.
    public func estimatedFinishDate(at date: Date? = nil) -> Date? {
        let now = date ?? timeSource.now
        switch phase {
            case .running(let deadline, _):
                return deadline
            case .paused(let remaining, _):
                return now.addingTimeInterval(remaining)
            case .idle, .completed:
                return nil
        }
    }

    /// Selects a duration preset and resets the timer to idle, unless a timer is actively running.
    public func selectPreset(_ preset: TimerPreset) {
        guard !phase.isRunning else { return }
        selectedPreset = preset
        if preset != .custom {
            activeDuration = preset.defaultDuration
        }
        phase = .idle
        saveSession()
        updateDockBadge()
    }

    /// Validates and sets a custom session duration in seconds (1s to 86400s / 24 hours).
    ///
    /// If valid, updates `selectedPreset` to `.custom`, stores `activeDuration`, resets `phase` to `.idle`, and returns `true`.
    /// If invalid, returns `false` without modifying state.
    @discardableResult
    public func setCustomDuration(_ seconds: TimeInterval) -> Bool {
        guard seconds > 0 && seconds <= 86_400 else {
            return false
        }
        selectedPreset = .custom
        activeDuration = seconds
        phase = .idle
        saveSession()
        updateDockBadge()
        return true
    }

    /// Evaluates whether the current deadline has elapsed and marks the timer as completed exactly once if applicable.
    public func evaluateDeadline(at date: Date? = nil) {
        let now = date ?? timeSource.now
        guard case .running(let deadline, let total) = phase else { return }
        if now >= deadline {
            phase = .completed(completedAt: deadline, totalDuration: total)
            if let token = activityToken {
                activityManager.endActivity(token)
                activityToken = nil
            }
            cancelCompletionNotification()
            if isAudioAlertEnabled {
                audioAlertPlayer.playCompletionAlert()
            }
            saveSession()
            updateDockBadge(at: now)
        }
    }

    /// Toggles the audio alert preference and persists the setting.
    public func toggleAudioAlert() {
        isAudioAlertEnabled.toggle()
        if case .running(let deadline, _) = phase {
            scheduleCompletionNotification(deadline: deadline)
        }
        saveSession()
    }

    /// Sets the audio alert preference and persists the setting.
    public func setAudioAlertEnabled(_ enabled: Bool) {
        guard isAudioAlertEnabled != enabled else { return }
        isAudioAlertEnabled = enabled
        if case .running(let deadline, _) = phase {
            scheduleCompletionNotification(deadline: deadline)
        }
        saveSession()
    }

    /// Toggles the always-on-top window pin state and persists the setting.
    public func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        saveSession()
    }

    /// Sets the always-on-top window pin state and persists the setting.
    public func setAlwaysOnTop(_ enabled: Bool) {
        guard isAlwaysOnTop != enabled else { return }
        isAlwaysOnTop = enabled
        saveSession()
    }

    /// Immediately handles system wake or application activation events.
    public func handleSystemWake() {
        evaluateDeadline()
        updateDockBadge()
    }

    /// Synchronizes the dock tile badge with the current countdown state.
    public func syncDockBadge(at date: Date? = nil) {
        updateDockBadge(at: date)
    }

    private func updateDockBadge(at date: Date? = nil) {
        let now = date ?? timeSource.now
        switch phase {
            case .idle:
                dockTileManager.setBadge(nil)
            case .running(let deadline, _):
                let remaining = max(0, deadline.timeIntervalSince(now))
                let minutes = Int(ceil(remaining / 60))
                if minutes > 0 {
                    dockTileManager.setBadge("\(minutes)m")
                } else {
                    dockTileManager.setBadge("<1m")
                }
            case .paused:
                dockTileManager.setBadge("⏸")
            case .completed:
                dockTileManager.setBadge("✔")
        }
    }

    /// The remaining countdown duration in seconds at a specified timestamp.
    ///
    /// When idle, returns `activeDuration` to drive static countdown previews.
    public func remainingDuration(at date: Date? = nil) -> TimeInterval {
        if case .idle = phase {
            return activeDuration
        }
        return TimerEngineCalculations.remainingDuration(
            in: phase,
            at: date ?? timeSource.now
        )
    }

    /// The fraction of elapsed progress between 0.0 and 1.0.
    ///
    /// When idle, returns `0.0`.
    public func progressFraction(at date: Date? = nil) -> Double {
        if case .idle = phase {
            return 0.0
        }
        return TimerEngineCalculations.progressFraction(
            in: phase,
            at: date ?? timeSource.now
        )
    }

    /// Formats the current remaining duration into a standard display string (e.g., "25:00").
    public func formattedCountdown(at date: Date? = nil) -> String {
        TimerEngineCalculations.formatCountdown(remainingDuration(at: date))
    }

    /// Awaits completion of in-flight notification tasks for deterministic testing and synchronization.
    public func waitForNotificationTasks() async {
        await notificationTask?.value
    }

    // MARK: - Private Helpers

    private func saveSession() {
        let session = PersistedTimerSession(
            phase: phase,
            selectedPreset: selectedPreset,
            activeDuration: activeDuration,
            isAudioAlertEnabled: isAudioAlertEnabled,
            isAlwaysOnTop: isAlwaysOnTop,
            savedAt: timeSource.now
        )
        persistence.save(session: session)
    }

    private func scheduleCompletionNotification(deadline: Date) {
        let remaining = max(0, deadline.timeIntervalSince(timeSource.now))
        guard remaining > 0 else { return }
        let scheduler = notificationScheduler
        let requestPermission = !hasRequestedNotificationPermission
        hasRequestedNotificationPermission = true
        let sound = isAudioAlertEnabled

        let previousTask = notificationTask
        previousTask?.cancel()
        notificationTask = Task {
            await previousTask?.value
            if requestPermission {
                _ = await scheduler.requestAuthorization()
            }
            guard !Task.isCancelled else { return }
            await scheduler.scheduleNotification(
                title: "Cadence",
                body: "Focus session complete.",
                triggerIn: remaining,
                identifier: Self.completionNotificationIdentifier,
                sound: sound
            )
        }
    }

    private func cancelCompletionNotification() {
        let previousTask = notificationTask
        previousTask?.cancel()
        let scheduler = notificationScheduler
        notificationTask = Task {
            await previousTask?.value
            await scheduler.cancelPendingNotifications(identifiers: [
                Self.completionNotificationIdentifier
            ])
        }
    }
}
