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
                isAudioAlertEnabled: true,
                isAlwaysOnTop: false,
                isHapticsEnabled: true,
                selectedAudioSound: .glass,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .running(targetDeadline: deadline, totalDuration: 1500),
                selectedPreset: .focus,
                activeDuration: 1500,
                isAudioAlertEnabled: false,
                isAlwaysOnTop: true,
                isHapticsEnabled: false,
                selectedAudioSound: .basso,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .paused(remainingDuration: 750, totalDuration: 1500),
                selectedPreset: .custom,
                activeDuration: 1500,
                isAudioAlertEnabled: true,
                isAlwaysOnTop: false,
                isHapticsEnabled: true,
                selectedAudioSound: .pop,
                savedAt: now
            ),
            PersistedTimerSession(
                phase: .completed(completedAt: deadline, totalDuration: 1500),
                selectedPreset: .quick,
                activeDuration: 300,
                isAudioAlertEnabled: true,
                isAlwaysOnTop: false,
                isHapticsEnabled: true,
                selectedAudioSound: .ping,
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
        // Legacy JSON without isAudioAlertEnabled, isHapticsEnabled, or selectedAudioSound
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
        #expect(decoded.isAlwaysOnTop == false)
        #expect(decoded.isHapticsEnabled == true)
        #expect(decoded.selectedAudioSound == .glass)
        #expect(decoded.activeDuration == 1500)
        #expect(decoded.selectedPreset == .focus)

        // Session with audio disabled and alwaysOnTop enabled
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let customSession = PersistedTimerSession(
            phase: .idle,
            selectedPreset: .deepWork,
            activeDuration: 3000,
            isAudioAlertEnabled: false,
            isAlwaysOnTop: true,
            isHapticsEnabled: false,
            selectedAudioSound: .basso,
            savedAt: now
        )
        let encoded = try JSONEncoder().encode(customSession)
        let roundTripped = try JSONDecoder().decode(PersistedTimerSession.self, from: encoded)
        #expect(roundTripped.isAudioAlertEnabled == false)
        #expect(roundTripped.isAlwaysOnTop == true)
        #expect(roundTripped.isHapticsEnabled == false)
        #expect(roundTripped.selectedAudioSound == .basso)
    }

    @Test("PersistedTimerSession backward compatibility for missing always-on-top preference")
    func testAlwaysOnTopBackwardCompatibility() throws {
        // v0.1.0-alpha.1 JSON with isAudioAlertEnabled but without isAlwaysOnTop or new v0.3.0 fields
        let alpha1JSON = """
            {
                "phase": { "idle": {} },
                "selectedPreset": "focus",
                "activeDuration": 1500,
                "isAudioAlertEnabled": true,
                "savedAt": 1700000000
            }
            """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(PersistedTimerSession.self, from: alpha1JSON)
        #expect(decoded.isAlwaysOnTop == false)
        #expect(decoded.isAudioAlertEnabled == true)
        #expect(decoded.isHapticsEnabled == true)
        #expect(decoded.selectedAudioSound == .glass)
    }
}
