import CadenceCore
import CadenceUI
import SwiftUI

@main
struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(CadenceAppDelegate.self) private var appDelegate
    @CadenceState private var store = TimerStore(
        persistence: UserDefaultsTimerPersistence(),
        notificationScheduler: UNNotificationScheduler(),
        audioAlertPlayer: AppKitAudioPlayer(),
        dockTileManager: AppKitDockTileManager()
    )

    var body: some Scene {
        Window("Cadence", id: "main") {
            MainWindowView(store: store)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 440, height: 530)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Timer") {
                Button(store.phase.isRunning ? "Pause" : "Start") {
                    store.toggle()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Reset") {
                    store.reset()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(store.phase.isIdle)

                Divider()

                Menu("Presets") {
                    Button("Quick: 5 Minutes") {
                        store.selectPreset(.quick)
                    }
                    .keyboardShortcut("1", modifiers: [.command])

                    Button("Focus: 25 Minutes") {
                        store.selectPreset(.focus)
                    }
                    .keyboardShortcut("2", modifiers: [.command])

                    Button("Deep Work: 50 Minutes") {
                        store.selectPreset(.deepWork)
                    }
                    .keyboardShortcut("3", modifiers: [.command])

                    Button("Long Session: 90 Minutes") {
                        store.selectPreset(.longSession)
                    }
                    .keyboardShortcut("4", modifiers: [.command])
                }
                .disabled(store.phase.isRunning)

                Button("Custom Duration...") {
                    store.isCustomSheetPresented = true
                }
                .keyboardShortcut("k", modifiers: [.command])
                .disabled(store.phase.isRunning)

                Divider()

                Button(store.isAlwaysOnTop ? "✓ Keep Window on Top" : "Keep Window on Top") {
                    store.toggleAlwaysOnTop()
                }
                .keyboardShortcut("p", modifiers: [.command])

                Button(store.isAudioAlertEnabled ? "✓ Audio Alert Chime" : "Audio Alert Chime") {
                    store.toggleAudioAlert()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            CadenceMenuBarMenu(store: store)
        } label: {
            CadenceMenuBarLabel(store: store)
        }
    }
}
