import Foundation
import Testing

@testable import CadenceCore

@Suite("Audio Alert Contract Tests")
struct AudioAlertTests {
    @Test("MockAudioAlertPlayer tracks play invocations correctly")
    func testMockAudioAlertPlayer() {
        let player = MockAudioAlertPlayer()
        #expect(player.playCount == 0)

        player.playCompletionAlert()
        #expect(player.playCount == 1)

        player.playCompletionAlert()
        #expect(player.playCount == 2)

        player.clear()
        #expect(player.playCount == 0)
    }

    @Test("NoOpAudioAlertPlayer executes safely without error")
    func testNoOpAudioAlertPlayer() {
        let player = NoOpAudioAlertPlayer()
        player.playCompletionAlert()
        #expect(true)
    }
}
