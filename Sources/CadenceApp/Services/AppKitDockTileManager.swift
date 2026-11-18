import AppKit
import CadenceCore

/// AppKit implementation of DockTileManagerProtocol manipulating NSApp.dockTile.badgeLabel.
public final class AppKitDockTileManager: DockTileManagerProtocol, @unchecked Sendable {
    public init() {}

    public func setBadge(_ label: String?) {
        Task { @MainActor in
            NSApp.dockTile.badgeLabel = label
        }
    }
}
