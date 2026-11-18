import Foundation
import Testing

@testable import CadenceCore

@Suite("Timer Engine Architectural Model Tests")
struct TimerModelTests {
    @Test("Timer starts at target deadline")
    func testTimerStart() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        let phase = TimerEngineCalculations.start(duration: 300, from: clock.now)

        if case .running(let deadline, let total) = phase {
            #expect(total == 300)
            #expect(deadline == Date(timeIntervalSince1970: 10300))
        } else {
            Issue.record("Expected running phase")
        }
    }

    @Test("Remaining duration calculates correctly without integer decrementing")
    func testRemainingDuration() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        let phase = TimerEngineCalculations.start(duration: 300, from: clock.now)

        #expect(TimerEngineCalculations.remainingDuration(in: phase, at: clock.now) == 300)

        // Advance simulated clock by 100 seconds
        clock.advance(by: 100)
        #expect(TimerEngineCalculations.remainingDuration(in: phase, at: clock.now) == 200)

        // Advance simulated clock past deadline (e.g. system sleep)
        clock.advance(by: 300)
        #expect(TimerEngineCalculations.remainingDuration(in: phase, at: clock.now) == 0)
    }

    @Test("Pausing and resuming preserves exact remaining duration")
    func testPauseAndResume() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        let runningPhase = TimerEngineCalculations.start(duration: 600, from: clock.now)

        // Advance 150 seconds
        clock.advance(by: 150)
        let pausedPhase = TimerEngineCalculations.pause(currentPhase: runningPhase, at: clock.now)

        if case .paused(let remaining, let total) = pausedPhase {
            #expect(remaining == 450)
            #expect(total == 600)
        } else {
            Issue.record("Expected paused phase")
        }

        // Advance clock while paused (e.g. app inactive for an hour)
        clock.advance(by: 3600)

        // Resume: deadline must now be now + 450
        let resumedPhase = TimerEngineCalculations.resume(currentPhase: pausedPhase, at: clock.now)
        if case .running(let deadline, let total) = resumedPhase {
            #expect(total == 600)
            #expect(deadline.timeIntervalSince(clock.now) == 450)
        } else {
            Issue.record("Expected resumed running phase")
        }
    }

    @Test("Progress fraction scales from 0.0 to 1.0")
    func testProgressFraction() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        let phase = TimerEngineCalculations.start(duration: 200, from: clock.now)

        #expect(TimerEngineCalculations.progressFraction(in: phase, at: clock.now) == 0.0)

        clock.advance(by: 50)
        #expect(
            abs(TimerEngineCalculations.progressFraction(in: phase, at: clock.now) - 0.25) < 0.001)

        clock.advance(by: 150)
        #expect(TimerEngineCalculations.progressFraction(in: phase, at: clock.now) == 1.0)
    }

    @Test("Deadline evaluation marks completed when clock passes deadline")
    func testDeadlineEvaluation() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        let running = TimerEngineCalculations.start(duration: 60, from: clock.now)

        let intermediate = TimerEngineCalculations.evaluateDeadline(
            currentPhase: running, at: clock.now)
        #expect(intermediate.isRunning)

        clock.advance(by: 61)
        let completed = TimerEngineCalculations.evaluateDeadline(
            currentPhase: running, at: clock.now)
        #expect(completed.isCompleted)
    }

    @Test("Time countdown formatting outputs clean representation")
    func testCountdownFormatting() {
        #expect(TimerEngineCalculations.formatCountdown(1500) == "25:00")
        #expect(TimerEngineCalculations.formatCountdown(65) == "01:05")
        #expect(TimerEngineCalculations.formatCountdown(9) == "00:09")
        #expect(TimerEngineCalculations.formatCountdown(3665) == "01:01:05")
    }

    @Test("Accessible natural-language duration formatting for VoiceOver")
    func testAccessibleDurationFormatting() {
        #expect(TimerEngineCalculations.accessibleDuration(0) == "0 seconds")
        #expect(TimerEngineCalculations.accessibleDuration(1) == "1 second")
        #expect(TimerEngineCalculations.accessibleDuration(45) == "45 seconds")
        #expect(TimerEngineCalculations.accessibleDuration(60) == "1 minute")
        #expect(TimerEngineCalculations.accessibleDuration(65) == "1 minute, 5 seconds")
        #expect(TimerEngineCalculations.accessibleDuration(300) == "5 minutes")
        #expect(TimerEngineCalculations.accessibleDuration(299) == "4 minutes, 59 seconds")
        #expect(TimerEngineCalculations.accessibleDuration(1500) == "25 minutes")
        #expect(TimerEngineCalculations.accessibleDuration(3600) == "1 hour")
        #expect(TimerEngineCalculations.accessibleDuration(3661) == "1 hour, 1 minute, 1 second")
        #expect(TimerEngineCalculations.accessibleDuration(5400) == "1 hour, 30 minutes")
    }

    @Test("Nonpositive duration start returns idle phase")
    func testNonpositiveDurationStart() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))
        #expect(TimerEngineCalculations.start(duration: 0, from: clock.now) == .idle)
        #expect(TimerEngineCalculations.start(duration: -10, from: clock.now) == .idle)
    }

    @Test("State idempotency for redundant operations")
    func testStateIdempotency() {
        let clock = SimulatedTimeSource(initialTime: Date(timeIntervalSince1970: 10000))

        // Pausing or resuming an idle timer preserves idle
        #expect(TimerEngineCalculations.pause(currentPhase: .idle, at: clock.now) == .idle)
        #expect(TimerEngineCalculations.resume(currentPhase: .idle, at: clock.now) == .idle)

        // Resuming an already running timer preserves the running phase
        let running = TimerEngineCalculations.start(duration: 100, from: clock.now)
        #expect(TimerEngineCalculations.resume(currentPhase: running, at: clock.now) == running)

        // Pausing an already paused timer preserves the paused phase
        let paused = TimerEngineCalculations.pause(currentPhase: running, at: clock.now)
        #expect(TimerEngineCalculations.pause(currentPhase: paused, at: clock.now) == paused)
    }
}
