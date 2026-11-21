import Foundation
import Testing

@testable import CadenceCore

@Suite("Audio Alert Contract Tests")
struct AudioAlertTests {
    @Test("MockAudioAlertPlayer tracks play invocations correctly")
    func testMockAudioAlertPlayer() {
        let player = MockAudioAlertPlayer()
        #expect(player.playCount == 0)
        #expect(player.playedSounds.isEmpty)

        player.playCompletionAlert()
        #expect(player.playCount == 1)
        #expect(player.playedSounds == [.glass])

        player.playCompletionAlert(sound: .basso)
        #expect(player.playCount == 2)
        #expect(player.playedSounds == [.glass, .basso])

        player.clear()
        #expect(player.playCount == 0)
        #expect(player.playedSounds.isEmpty)
    }

    @Test("NoOpAudioAlertPlayer executes safely without error")
    func testNoOpAudioAlertPlayer() {
        let player = NoOpAudioAlertPlayer()
        player.playCompletionAlert()
        player.playCompletionAlert(sound: .ping)
        #expect(true)
    }

    @Test("AudioAlertSound enum cases and display names")
    func testAudioAlertSoundEnum() {
        #expect(AudioAlertSound.allCases.count == 7)
        #expect(AudioAlertSound.glass.rawValue == "Glass")
        #expect(AudioAlertSound.glass.id == "Glass")
        #expect(AudioAlertSound.glass.displayName.contains("Glass"))
        #expect(AudioAlertSound.basso.displayName.contains("Basso"))
        #expect(AudioAlertSound.pop.displayName.contains("Pop"))
        #expect(AudioAlertSound.ping.displayName.contains("Ping"))
        #expect(AudioAlertSound.tink.displayName.contains("Tink"))
        #expect(AudioAlertSound.purr.displayName.contains("Purr"))
        #expect(AudioAlertSound.sosumi.displayName.contains("Sosumi"))
    }
}
