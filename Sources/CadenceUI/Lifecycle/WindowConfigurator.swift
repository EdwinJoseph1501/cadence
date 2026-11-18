import AppKit
import SwiftUI

/// Invisible NSViewRepresentable that attaches to the host NSWindow and applies native window configuration.
public struct WindowConfigurator: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        let view = WindowConfiguratorHostingView()
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class WindowConfiguratorHostingView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            Task { @MainActor in
                WindowLifecycleController.shared.configure(window: window)
            }
        }
    }
}
