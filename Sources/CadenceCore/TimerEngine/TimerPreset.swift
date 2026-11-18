import Foundation

/// Standard focus session duration presets supported by Cadence.
public enum TimerPreset: String, CaseIterable, Identifiable, Sendable, Codable {
    case quick = "quick"
    case focus = "focus"
    case deepWork = "deepWork"
    case longSession = "longSession"
    case custom = "custom"

    public var id: String {
        rawValue
    }

    /// User-facing display title for the preset.
    public var displayName: String {
        switch self {
            case .quick:
                return "Quick"
            case .focus:
                return "Focus"
            case .deepWork:
                return "Deep Work"
            case .longSession:
                return "Long Session"
            case .custom:
                return "Custom"
        }
    }

    /// Default countdown duration in seconds.
    public var defaultDuration: TimeInterval {
        switch self {
            case .quick:
                return 300
            case .focus:
                return 1500
            case .deepWork:
                return 3000
            case .longSession:
                return 5400
            case .custom:
                return 1500
        }
    }
}
