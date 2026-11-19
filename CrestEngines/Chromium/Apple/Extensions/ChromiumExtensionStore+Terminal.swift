import Foundation

/// `arma extension` over Chromium's per-Space profiles: the same core intents
/// and install review the Extensions settings pane uses.
extension ChromiumExtensionStore: BrowserMacExtensionManaging {
    // MARK: - Actions - Terminal

    /// What the core lists for `space`'s profile, once the engine has listed
    /// it, or nil for a Space the core keeps from the terminal.
    func installedExtensions(in space: BrowserSpaceIdentity) async -> [InstalledExtension]? {
        guard mayChange(space) else { return nil }
        load(space)
        // The engine lists the profile in its own time; give it a few seconds.
        for _ in 0..<50 {
            if let listed = ChromiumComposition.core?.state.installedExtensions[.chromium]?[space.profileID] {
                return listed
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return nil
    }

    func change(_ change: ExtensionChange, extensionID: String, in space: BrowserSpaceIdentity) -> Bool {
        guard mayChange(space),
            let command = [ExtensionCommand.enable, .disable, .remove, .pin, .unpin].first(where: {
                $0.change == change
            })
        else {
            return false
        }
        let accepted = self.command(command, extensionID: extensionID, space: space)
        refresh()
        return accepted
    }

    func reviewInstall(of webStoreID: String, in space: BrowserSpaceIdentity) -> Bool {
        guard installation == nil, mayChange(space), ChromiumComposition.activeNativeWindow != nil else {
            return false
        }
        install(webStoreID, in: space, anchor: nil)
        return installation != nil
    }
}
