import AppKit
import CadenceCore
import CadenceUI
import SwiftUI

public struct MainWindowView: View {
    public let store: TimerStore

    public init(
        store: TimerStore = TimerStore(
            persistence: UserDefaultsTimerPersistence(),
            notificationScheduler: UNNotificationScheduler(),
            audioAlertPlayer: AppKitAudioPlayer(),
            dockTileManager: AppKitDockTileManager()
        )
    ) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.cadenceBackground
                .ignoresSafeArea()

            CadenceTimerView(store: store)

            // Hidden keyboard shortcut handlers (guarded against modal text entry)
            Group {
                Button("Toggle Timer") {
                    guard !store.isCustomSheetPresented else { return }
                    store.toggle()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Reset Timer") {
                    guard !store.isCustomSheetPresented else { return }
                    store.reset()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Remove 1 Minute") {
                    guard !store.isCustomSheetPresented else { return }
                    store.adjustDuration(by: -60)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("Add 1 Minute") {
                    guard !store.isCustomSheetPresented else { return }
                    store.adjustDuration(by: 60)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Toggle Audio Alert") {
                    guard !store.isCustomSheetPresented else { return }
                    store.toggleAudioAlert()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Button("Quick Preset") {
                    guard !store.isCustomSheetPresented else { return }
                    store.selectPreset(.quick)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Focus Preset") {
                    guard !store.isCustomSheetPresented else { return }
                    store.selectPreset(.focus)
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Deep Work Preset") {
                    guard !store.isCustomSheetPresented else { return }
                    store.selectPreset(.deepWork)
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Long Session Preset") {
                    guard !store.isCustomSheetPresented else { return }
                    store.selectPreset(.longSession)
                }
                .keyboardShortcut("4", modifiers: [.command])

                Button("Toggle Always-On-Top") {
                    guard !store.isCustomSheetPresented else { return }
                    store.toggleAlwaysOnTop()
                }
                .keyboardShortcut("p", modifiers: [.command])
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(
            minWidth: 400,
            idealWidth: 440,
            maxWidth: 500,
            minHeight: 520,
            idealHeight: 560,
            maxHeight: 620
        )
        .background(Color.cadenceBackground)
        .background(WindowConfigurator())
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            store.handleSystemWake()
        }
        .onReceive(
            NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
        ) { _ in
            store.handleSystemWake()
        }
        .onChange(of: store.isAlwaysOnTop, initial: true) { _, isPinned in
            WindowLifecycleController.shared.setAlwaysOnTop(isPinned)
        }
    }
}
