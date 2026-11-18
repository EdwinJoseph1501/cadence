import Foundation

/// Explicit algebraic representation of the timer lifecycle.
///
/// Crucially, countdown state is NOT stored as a decremented integer tick.
/// In `.running` mode, the remaining time is a pure function of `targetDeadline - now`.
/// This guarantees immunity to clock drift, thread suspension, and system sleep.
public enum TimerPhase: Sendable, Equatable, Codable {
    case idle
    case running(targetDeadline: Date, totalDuration: TimeInterval)
    case paused(remainingDuration: TimeInterval, totalDuration: TimeInterval)
    case completed(completedAt: Date, totalDuration: TimeInterval)

    /// Returns whether the timer is currently actively running towards a deadline.
    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    /// Returns whether the timer is paused with duration preserved.
    public var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    /// Returns whether the timer has completed.
    public var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }
}

/// Pure functional calculations for timer state and remaining duration.
public enum TimerEngineCalculations: Sendable {
    /// Computes the exact remaining duration for a given phase at a specific point in time.
    public static func remainingDuration(in phase: TimerPhase, at currentTime: Date) -> TimeInterval
    {
        switch phase {
            case .idle:
                return 0.0
            case .running(let targetDeadline, _):
                return max(0.0, targetDeadline.timeIntervalSince(currentTime))
            case .paused(let remaining, _):
                return max(0.0, remaining)
            case .completed:
                return 0.0
        }
    }

    /// Computes the progress fraction (from 0.0 at start to 1.0 at completion).
    public static func progressFraction(in phase: TimerPhase, at currentTime: Date) -> Double {
        switch phase {
            case .idle:
                return 0.0
            case .running(let targetDeadline, let total):
                guard total > 0 else { return 1.0 }
                let remaining = max(0.0, targetDeadline.timeIntervalSince(currentTime))
                let elapsed = total - remaining
                return min(max(elapsed / total, 0.0), 1.0)
            case .paused(let remaining, let total):
                guard total > 0 else { return 1.0 }
                let elapsed = total - remaining
                return min(max(elapsed / total, 0.0), 1.0)
            case .completed:
                return 1.0
        }
    }

    /// Initiates a countdown from a given duration starting at `now`.
    public static func start(duration: TimeInterval, from now: Date) -> TimerPhase {
        guard duration > 0 else { return .idle }
        let deadline = now.addingTimeInterval(duration)
        return .running(targetDeadline: deadline, totalDuration: duration)
    }

    /// Pauses an actively running countdown, locking in the remaining duration.
    public static func pause(currentPhase: TimerPhase, at now: Date) -> TimerPhase {
        switch currentPhase {
            case .running(let targetDeadline, let totalDuration):
                let remaining = max(0.0, targetDeadline.timeIntervalSince(now))
                if remaining <= 0 {
                    return .completed(completedAt: now, totalDuration: totalDuration)
                }
                return .paused(remainingDuration: remaining, totalDuration: totalDuration)
            case .idle, .paused, .completed:
                return currentPhase
        }
    }

    /// Resumes a paused countdown, calculating a fresh deadline from `now + remainingDuration`.
    public static func resume(currentPhase: TimerPhase, at now: Date) -> TimerPhase {
        switch currentPhase {
            case .paused(let remaining, let total):
                guard remaining > 0 else {
                    return .completed(completedAt: now, totalDuration: total)
                }
                let deadline = now.addingTimeInterval(remaining)
                return .running(targetDeadline: deadline, totalDuration: total)
            case .idle, .running, .completed:
                return currentPhase
        }
    }

    /// Evaluates if an active countdown has elapsed past its deadline.
    public static func evaluateDeadline(currentPhase: TimerPhase, at now: Date) -> TimerPhase {
        switch currentPhase {
            case .running(let deadline, let total):
                if now >= deadline {
                    return .completed(completedAt: deadline, totalDuration: total)
                }
                return currentPhase
            case .idle, .paused, .completed:
                return currentPhase
        }
    }

    /// Formats a time interval in seconds into a clean human-readable countdown string (e.g. "25:00" or "01:15:30").
    public static func formatCountdown(_ seconds: TimeInterval) -> String {
        let rounded = max(0, Int(ceil(seconds)))
        let hrs = rounded / 3600
        let mins = (rounded % 3600) / 60
        let secs = rounded % 60

        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    /// Formats a time interval in seconds into a natural-language description suitable for VoiceOver (e.g. "5 minutes" or "4 minutes, 59 seconds").
    public static func accessibleDuration(_ seconds: TimeInterval) -> String {
        let rounded = max(0, Int(ceil(seconds)))
        let hrs = rounded / 3600
        let mins = (rounded % 3600) / 60
        let secs = rounded % 60

        var components: [String] = []
        if hrs > 0 {
            components.append("\(hrs) \(hrs == 1 ? "hour" : "hours")")
        }
        if mins > 0 {
            components.append("\(mins) \(mins == 1 ? "minute" : "minutes")")
        }
        if secs > 0 || components.isEmpty {
            components.append("\(secs) \(secs == 1 ? "second" : "seconds")")
        }

        return components.joined(separator: ", ")
    }
}
