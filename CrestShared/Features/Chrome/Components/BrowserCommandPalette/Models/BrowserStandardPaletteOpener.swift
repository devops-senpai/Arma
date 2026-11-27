import Foundation

/// Shared command-palette URL opener used by both macOS and mobile window root
/// models. Handles in-place and new-tab opening once, while optional closures
/// supply platform-specific Split View and Quick Window actions.
@MainActor
struct BrowserStandardPaletteOpener: BrowserCommandPaletteOpener {
    // MARK: - Variables

    let browser: BrowserStore
    let mode: BrowserCommandPaletteMode
    let loadInShownPage: @MainActor (URL) -> Void
    /// Presents a tab that just took the address, where selecting it starts
    /// its page loading; nil loads it in the shown page instead.
    var showOpened: (@MainActor (URL) -> Void)? = nil
    var openSplit: (@MainActor (URL, BrowserTabRuntimeAssignment) -> Bool)? = nil
    var openQuickWindow: (@MainActor (URL, BrowserTabRuntimeAssignment) -> Bool)? = nil

    // MARK: - Actions - Opening

    func openHere(_ url: URL, from source: BrowserTabRuntimeAssignment) -> Bool {
        if mode == .newTab { return openTab(url, from: source, selecting: true) }
        // A Start Page or native tab has no page, so the core gives it the
        // address and selecting it opens its page loading it; loading again
        // would send a second LoadPage. A tab showing a page keeps the load.
        if let showOpened, browser.shownTab?.surface.showsPage == false {
            guard browser.navigateSelectedTab(to: url.absoluteString) else { return false }
            showOpened(url)
            return true
        }
        browser.navigateSelectedTab(to: url.absoluteString)
        loadInShownPage(url)
        return true
    }

    func openTab(_ url: URL, from source: BrowserTabRuntimeAssignment, selecting: Bool) -> Bool {
        guard selecting else {
            return browser.openBackgroundTab(url: url, in: source.spaceID, savesInSavedFolder: true) != nil
        }
        guard browser.openAddress(url, in: source.spaceID, placesAsNewTab: true) else { return false }
        // Selecting the new tab starts its first navigation.
        (showOpened ?? loadInShownPage)(url)
        return true
    }

    func openInSplit(_ url: URL, from source: BrowserTabRuntimeAssignment) -> Bool {
        openSplit?(url, source) ?? false
    }

    func openInQuickWindow(_ url: URL, from source: BrowserTabRuntimeAssignment) -> Bool {
        openQuickWindow?(url, source) ?? false
    }
}
