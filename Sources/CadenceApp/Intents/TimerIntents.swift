import AppIntents
import CadenceCore
import CadenceUI
import Foundation

public struct StartTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start Focus Timer"
    public static let description = IntentDescription(
        "Starts or resumes the Cadence focus countdown."
    )
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        CadenceApp.sharedStore.start()
        let formatted = CadenceApp.sharedStore.formattedCountdown()
        return .result(dialog: "Started Cadence timer for \(formatted).")
    }
}

public struct PauseTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Pause Focus Timer"
    public static let description = IntentDescription(
        "Pauses an active Cadence focus countdown."
    )
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        CadenceApp.sharedStore.pause()
        let formatted = CadenceApp.sharedStore.formattedCountdown()
        return .result(dialog: "Paused Cadence timer at \(formatted).")
    }
}

public struct ToggleTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Toggle Focus Timer"
    public static let description = IntentDescription(
        "Starts, pauses, or resumes the Cadence focus countdown."
    )
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        CadenceApp.sharedStore.toggle()
        let status: String
        let formatted = CadenceApp.sharedStore.formattedCountdown()
        switch CadenceApp.sharedStore.phase {
            case .running:
                status = "Timer running (\(formatted) remaining)."
            case .paused:
                status = "Timer paused at \(formatted)."
            case .completed:
                status = "Timer completed."
            case .idle:
                status = "Timer ready at \(formatted)."
        }
        return .result(dialog: "\(status)")
    }
}

public struct ResetTimerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Reset Focus Timer"
    public static let description = IntentDescription(
        "Resets the Cadence timer back to idle state."
    )
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        CadenceApp.sharedStore.reset()
        let formatted = CadenceApp.sharedStore.formattedCountdown()
        return .result(dialog: "Cadence timer reset to \(formatted).")
    }
}

public enum TimerPresetAppEnum: String, AppEnum, Sendable {
    case quick = "quick"
    case focus = "focus"
    case deepWork = "deepWork"
    case longSession = "longSession"

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Timer Preset"
    public static let caseDisplayRepresentations: [TimerPresetAppEnum: DisplayRepresentation] = [
        .quick: "Quick (5m)",
        .focus: "Focus (25m)",
        .deepWork: "Deep Work (50m)",
        .longSession: "Long Session (90m)",
    ]

    public var corePreset: TimerPreset {
        switch self {
            case .quick: return .quick
            case .focus: return .focus
            case .deepWork: return .deepWork
            case .longSession: return .longSession
        }
    }
}

public struct SetPresetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Set Timer Preset"
    public static let description = IntentDescription(
        "Sets Cadence to a specific preset duration."
    )
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Preset")
    public var preset: TimerPresetAppEnum

    public init() {}

    public init(preset: TimerPresetAppEnum) {
        self.preset = preset
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        CadenceApp.sharedStore.selectPreset(preset.corePreset)
        return .result(dialog: "Set timer to \(preset.corePreset.displayName).")
    }
}

public struct GetTimerStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Timer Status"
    public static let description = IntentDescription(
        "Returns the current countdown status and phase of Cadence."
    )
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog
        & ReturnsValue<String>
    {
        let store = CadenceApp.sharedStore
        let formatted = store.formattedCountdown()
        let status: String
        switch store.phase {
            case .idle:
                status = "Timer is idle at \(formatted)."
            case .running:
                status = "Focus session running with \(formatted) remaining."
            case .paused:
                status = "Focus session paused at \(formatted)."
            case .completed:
                status = "Focus session is complete."
        }
        return .result(value: status, dialog: "\(status)")
    }
}

public struct CadenceShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Start \(.applicationName) timer",
                "Start \(.applicationName)",
            ],
            shortTitle: "Start Timer",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: PauseTimerIntent(),
            phrases: [
                "Pause \(.applicationName) timer",
                "Pause \(.applicationName)",
            ],
            shortTitle: "Pause Timer",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: ToggleTimerIntent(),
            phrases: [
                "Toggle \(.applicationName) timer",
                "Toggle \(.applicationName)",
            ],
            shortTitle: "Toggle Timer",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: ResetTimerIntent(),
            phrases: [
                "Reset \(.applicationName) timer",
                "Reset \(.applicationName)",
            ],
            shortTitle: "Reset Timer",
            systemImageName: "arrow.counterclockwise"
        )
        AppShortcut(
            intent: GetTimerStatusIntent(),
            phrases: [
                "Check \(.applicationName) timer",
                "\(.applicationName) status",
            ],
            shortTitle: "Timer Status",
            systemImageName: "info.circle"
        )
    }
}
