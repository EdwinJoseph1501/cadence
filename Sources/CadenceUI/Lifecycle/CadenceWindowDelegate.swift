import AppKit

/// Native NSWindowDelegate managing window close and hide lifecycle.
@MainActor
public final class CadenceWindowDelegate: NSObject, NSWindowDelegate {
    public weak var controller: WindowLifecycleController?

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let controller, controller.isTerminating {
            return true
        }
        sender.orderOut(nil)
        return false
    }
}
