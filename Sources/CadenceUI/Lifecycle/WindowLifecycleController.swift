import AppKit
import CadenceCore

/// Coordinates native macOS window styling, lifecycle, and reopen restoration.
@MainActor
public final class WindowLifecycleController: NSObject {
    public static let shared = WindowLifecycleController()

    public private(set) weak var mainWindow: NSWindow?
    public private(set) var isTerminating: Bool = false
    public private(set) var isAlwaysOnTop: Bool = false

    public let windowDelegate: CadenceWindowDelegate

    public override init() {
        let delegate = CadenceWindowDelegate()
        self.windowDelegate = delegate
        super.init()
        delegate.controller = self
    }

    /// Configures the native window with Blood Moon styling and lifecycle delegates.
    public func configure(window: NSWindow) {
        self.mainWindow = window
        window.title = "Cadence"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true

        // Blood Moon Canvas color #140A10
        window.backgroundColor = NSColor(
            red: BloodMoonPalette.background.red,
            green: BloodMoonPalette.background.green,
            blue: BloodMoonPalette.background.blue,
            alpha: BloodMoonPalette.background.alpha
        )

        window.isReleasedWhenClosed = false
        window.delegate = windowDelegate

        window.minSize = NSSize(width: 400, height: 490)
        window.maxSize = NSSize(width: 500, height: 590)
        window.level = isAlwaysOnTop ? .floating : .normal
    }

    /// Sets the window level to floating or normal based on the always-on-top preference.
    public func setAlwaysOnTop(_ enabled: Bool) {
        self.isAlwaysOnTop = enabled
        mainWindow?.level = enabled ? .floating : .normal
    }

    /// Toggles the always-on-top window float state.
    public func toggleAlwaysOnTop() {
        setAlwaysOnTop(!isAlwaysOnTop)
    }

    /// Restores the main window when clicking the Dock icon or notification banner.
    public func restoreMainWindow() {
        guard
            let window = mainWindow
                ?? NSApp.windows.first(where: { $0.canBecomeMain })
                ?? NSApp.windows.first
        else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        if NSApp.isHidden {
            NSApp.unhide(nil)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Prepares for application termination so window close handlers do not cancel termination.
    public func prepareForTermination() {
        isTerminating = true
    }

    /// Resets state for deterministic unit testing.
    public func resetForTesting() {
        mainWindow = nil
        isTerminating = false
        isAlwaysOnTop = false
    }
}
