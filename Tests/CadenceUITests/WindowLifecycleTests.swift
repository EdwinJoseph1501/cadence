import AppKit
import CadenceCore
import CadenceUI
import SwiftUI
import Testing

@Suite("Window Lifecycle & Appearance Tests")
@MainActor
struct WindowLifecycleTests {
    @Test("WindowLifecycleController styles window with Blood Moon palette and native controls")
    func testWindowConfiguration() {
        let controller = WindowLifecycleController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        controller.configure(window: window)

        #expect(window.title == "Cadence")
        #expect(window.titlebarAppearsTransparent == true)
        #expect(window.titleVisibility == .hidden)
        #expect(window.styleMask.contains(.fullSizeContentView))
        #expect(window.isMovableByWindowBackground == true)
        #expect(window.isReleasedWhenClosed == false)
        #expect(window.minSize == NSSize(width: 400, height: 490))
        #expect(window.maxSize == NSSize(width: 500, height: 590))
        #expect(controller.mainWindow === window)
        #expect(!controller.isTerminating)
    }

    @Test("CadenceWindowDelegate orders out window when closing while app is running")
    func testWindowShouldCloseOrdersOutWhenRunning() {
        let controller = WindowLifecycleController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        controller.configure(window: window)

        window.makeKeyAndOrderFront(nil)
        #expect(window.isVisible)

        let shouldClose = controller.windowDelegate.windowShouldClose(window)
        #expect(!shouldClose)
        #expect(!window.isVisible)
    }

    @Test("CadenceWindowDelegate allows window close when app is terminating")
    func testWindowShouldCloseAllowsCloseWhenTerminating() {
        let controller = WindowLifecycleController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        controller.configure(window: window)

        controller.prepareForTermination()
        #expect(controller.isTerminating)

        let shouldClose = controller.windowDelegate.windowShouldClose(window)
        #expect(shouldClose)
    }

    @Test("restoreMainWindow restores ordered-out window")
    func testRestoreMainWindow() {
        let controller = WindowLifecycleController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        controller.configure(window: window)

        window.orderOut(nil)
        #expect(!window.isVisible)

        controller.restoreMainWindow()
        #expect(window.isVisible)

        window.orderOut(nil)
    }

    @Test("WindowLifecycleController toggles always-on-top window level")
    func testAlwaysOnTopWindowLevel() {
        let controller = WindowLifecycleController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        controller.configure(window: window)

        #expect(!controller.isAlwaysOnTop)
        #expect(window.level == .normal)

        controller.setAlwaysOnTop(true)
        #expect(controller.isAlwaysOnTop)
        #expect(window.level == .floating)

        controller.toggleAlwaysOnTop()
        #expect(!controller.isAlwaysOnTop)
        #expect(window.level == .normal)

        // Reset and reconfigure with initial always-on-top true
        controller.resetForTesting()
        controller.setAlwaysOnTop(true)
        let window2 = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        controller.configure(window: window2)
        #expect(window2.level == .floating)
    }
}
