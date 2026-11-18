import AppKit
import CadenceCore
import CadenceUI
import SwiftUI

public struct MainWindowView: View {
    @CadenceState private var store: TimerStore

    public init(
        store: TimerStore = TimerStore(
            persistence: UserDefaultsTimerPersistence(),
            notificationScheduler: UNNotificationScheduler(),
            audioAlertPlayer: AppKitAudioPlayer()
        )
    ) {
        self._store = CadenceState(initialValue: store)
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
            minHeight: 490,
            idealHeight: 530,
            maxHeight: 590
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
    }
}
