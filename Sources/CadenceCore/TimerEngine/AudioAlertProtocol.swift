import Foundation

/// Curated system sounds for Cadence completion alerts.
public enum AudioAlertSound: String, CaseIterable, Identifiable, Codable, Sendable {
    case glass = "Glass"
    case ping = "Ping"
    case tink = "Tink"
    case purr = "Purr"
    case pop = "Pop"
    case basso = "Basso"
    case sosumi = "Sosumi"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
            case .glass: return "Glass (Crisp Chime)"
            case .ping: return "Ping (Clean Note)"
            case .tink: return "Tink (Subtle Tap)"
            case .purr: return "Purr (Warm Resonance)"
            case .pop: return "Pop (Woodblock)"
            case .basso: return "Basso (Deep Gong)"
            case .sosumi: return "Sosumi (Legacy Tone)"
        }
    }
}

/// Pure contract for playing audio completion alerts.
///
/// Decoupled from AppKit to ensure CadenceCore remains pure Swift.
public protocol AudioAlertProtocol: Sendable {
    func playCompletionAlert(sound: AudioAlertSound)
}

extension AudioAlertProtocol {
    public func playCompletionAlert() {
        playCompletionAlert(sound: .glass)
    }
}

/// No-op audio alert player for previews and disabled audio states.
public struct NoOpAudioAlertPlayer: AudioAlertProtocol {
    public init() {}
    public func playCompletionAlert(sound: AudioAlertSound) {}
}

/// Mock audio alert player recording audio events for deterministic unit tests.
public final class MockAudioAlertPlayer: AudioAlertProtocol, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var playCount: Int = 0
    public private(set) var playedSounds: [AudioAlertSound] = []

    public init() {}

    public func playCompletionAlert(sound: AudioAlertSound) {
        lock.lock()
        defer { lock.unlock() }
        playCount += 1
        playedSounds.append(sound)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        playCount = 0
        playedSounds.removeAll()
    }
}
