import AppKit
import CadenceCore

/// Native macOS audio alert player using system sound services via AppKit NSSound.
public final class AppKitAudioPlayer: AudioAlertProtocol, @unchecked Sendable {
    private let soundName: String

    public init(soundName: String = "Glass") {
        self.soundName = soundName
    }

    public func playCompletionAlert() {
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
