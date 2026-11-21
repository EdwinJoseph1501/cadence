import Foundation

/// Serializable representation of the timer's state for persistence and recovery across application restarts.
public struct PersistedTimerSession: Codable, Sendable, Equatable {
    public let phase: TimerPhase
    public let selectedPreset: TimerPreset
    public let activeDuration: TimeInterval
    public let isAudioAlertEnabled: Bool
    public let isAlwaysOnTop: Bool
    public let isHapticsEnabled: Bool
    public let selectedAudioSound: AudioAlertSound
    public let savedAt: Date

    public init(
        phase: TimerPhase,
        selectedPreset: TimerPreset,
        activeDuration: TimeInterval,
        isAudioAlertEnabled: Bool = true,
        isAlwaysOnTop: Bool = false,
        isHapticsEnabled: Bool = true,
        selectedAudioSound: AudioAlertSound = .glass,
        savedAt: Date
    ) {
        self.phase = phase
        self.selectedPreset = selectedPreset
        self.activeDuration = min(max(activeDuration, 1), 86_400)
        self.isAudioAlertEnabled = isAudioAlertEnabled
        self.isAlwaysOnTop = isAlwaysOnTop
        self.isHapticsEnabled = isHapticsEnabled
        self.selectedAudioSound = selectedAudioSound
        self.savedAt = savedAt
    }

    private enum CodingKeys: String, CodingKey {
        case phase
        case selectedPreset
        case activeDuration
        case isAudioAlertEnabled
        case isAlwaysOnTop
        case isHapticsEnabled
        case selectedAudioSound
        case savedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phase = try container.decode(TimerPhase.self, forKey: .phase)
        self.selectedPreset = try container.decode(TimerPreset.self, forKey: .selectedPreset)
        let rawDuration = try container.decode(TimeInterval.self, forKey: .activeDuration)
        self.activeDuration = min(max(rawDuration, 1), 86_400)
        self.isAudioAlertEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .isAudioAlertEnabled) ?? true
        self.isAlwaysOnTop =
            try container.decodeIfPresent(Bool.self, forKey: .isAlwaysOnTop) ?? false
        self.isHapticsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .isHapticsEnabled) ?? true
        self.selectedAudioSound =
            try container.decodeIfPresent(AudioAlertSound.self, forKey: .selectedAudioSound)
            ?? .glass
        self.savedAt = try container.decode(Date.self, forKey: .savedAt)
    }
}
