import AppKit
import CadenceCore

/// Native macOS audio alert player using system sound services via AppKit NSSound.
public final class AppKitAudioPlayer: AudioAlertProtocol, @unchecked Sendable {
    public init() {}

    public func playCompletionAlert(sound: AudioAlertSound = .glass) {
        if let nsSound = NSSound(named: NSSound.Name(sound.rawValue)) {
            nsSound.play()
        } else {
            NSSound.beep()
        }
    }
}
