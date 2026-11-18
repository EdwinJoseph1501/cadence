import Foundation
import Testing

@testable import CadenceCore

@Suite("Timer Persistence & Session Tests")
struct PersistenceModelTests {
    @Test("PersistedTimerSession round-trip serialization across all phases")
    func testSessionSerialization() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let deadline = now.addingTimeInterval(1500)

        let sessions: [PersistedTimerSession] = [
            PersistedTimerSession(
                phase: .idle,
                selectedPreset: .focus,
                activeDuration: 1500,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .running(targetDeadline: deadline, totalDuration: 1500),
                selectedPreset: .focus,
                activeDuration: 1500,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .paused(remainingDuration: 750, totalDuration: 1500),
                selectedPreset: .custom,
                activeDuration: 1500,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .completed(completedAt: deadline, totalDuration: 1500),
                selectedPreset: .quick,
                activeDuration: 300,
                savedAt: now
            ),
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for session in sessions {
            let data = try encoder.encode(session)
            let decoded = try decoder.decode(PersistedTimerSession.self, from: data)
            #expect(decoded == session)
        }
    }

    @Test("InMemoryTimerPersistence save, load, and clear")
    func testInMemoryPersistence() {
        let persistence = InMemoryTimerPersistence()
        #expect(persistence.loadSession() == nil)

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = PersistedTimerSession(
            phase: .idle,
            selectedPreset: .deepWork,
            activeDuration: 3000,
            savedAt: now
        )

        persistence.save(session: session)
        #expect(persistence.loadSession() == session)

        persistence.clearSession()
        #expect(persistence.loadSession() == nil)
    }

    @Test("UserDefaultsTimerPersistence save, load, clear, and corruption handling")
    func testUserDefaultsPersistence() {
        let suiteName = "com.cadence.test.persistence.\(UUID().uuidString)"
        let persistence = UserDefaultsTimerPersistence(suiteName: suiteName)

        #expect(persistence.loadSession() == nil)

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = PersistedTimerSession(
            phase: .running(targetDeadline: now.addingTimeInterval(300), totalDuration: 300),
            selectedPreset: .quick,
            activeDuration: 300,
            savedAt: now
        )

        persistence.save(session: session)
        #expect(persistence.loadSession() == session)

        persistence.clearSession()
        #expect(persistence.loadSession() == nil)

        // Test corrupted data handling
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults.set(
                Data([0xFF, 0xFE, 0x00]), forKey: "com.cadence.timer.persisted_session")
            #expect(persistence.loadSession() == nil)
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }

    @Test("PersistedTimerSession backward compatibility for missing audio preference")
    func testAudioPreferenceBackwardCompatibility() throws {
        // Legacy JSON without isAudioAlertEnabled
        let legacyJSON = """
            {
                "phase": { "idle": {} },
                "selectedPreset": "focus",
                "activeDuration": 1500,
                "savedAt": 1700000000
            }
            """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(PersistedTimerSession.self, from: legacyJSON)
        #expect(decoded.isAudioAlertEnabled == true)
        #expect(decoded.activeDuration == 1500)
        #expect(decoded.selectedPreset == .focus)

        // Session with audio disabled
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let mutedSession = PersistedTimerSession(
            phase: .idle,
            selectedPreset: .deepWork,
            activeDuration: 3000,
            isAudioAlertEnabled: false,
            savedAt: now
        )
        let encoded = try JSONEncoder().encode(mutedSession)
        let roundTripped = try JSONDecoder().decode(PersistedTimerSession.self, from: encoded)
        #expect(roundTripped.isAudioAlertEnabled == false)
    }
}
