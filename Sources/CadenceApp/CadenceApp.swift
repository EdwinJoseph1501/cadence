import CadenceCore
import CadenceUI
import SwiftUI

@main
struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(CadenceAppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Cadence", id: "main") {
            MainWindowView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 440, height: 530)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
