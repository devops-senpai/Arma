import Foundation

// MARK: - Types

/// The section of the sidebar a new tab goes to when it is not the open
/// tabs, as the terminal names it.
enum TerminalTabSection: String, Codable, Sendable, CaseIterable {
    case pinned
    case saved
}

/// `arma tab`: the tabs in the sidebar, as objects: where they are, what they
/// show and in which engine. What happens inside a tab's page is `arma page`.
///
/// A tab is named by a reference: `current` for the tab the front window
/// shows, its identifier, or the start of its identifier that `arma tab list`
/// prints. Where a tab lands in its list is a `TerminalPlace`, or last.
enum TerminalTabCommand: Codable, Sendable {
    /// The tabs of `space`, or of every Space; only those in `folder`, by
    /// name or path such as `Work/Clients`; only those with a live page
    /// when `loadedOnly`.
    case list(space: String?, folder: String?, loadedOnly: Bool)
    /// Opens `url` as a new tab of `space`, in `engine` when given, shown
    /// unless `background`. With no Space, the page opens in a Quick Window,
    /// whose Space menu picks where it goes. In a Space, the tab goes to the
    /// pinned or saved tabs when `section` says, into `folder` when given,
    /// where `place` says, and shows `title` instead of its page's.
    case open(
        url: String, space: String?, engine: TerminalEngine?, background: Bool, section: TerminalTabSection?,
        folder: String?, place: TerminalPlace?, title: String?)
    /// Closes tab `tab`; a pinned or saved tab's page is put away.
    case close(tab: String)
    /// Brings tab `tab` forward in a window.
    case show(tab: String)
    /// Reloads tab `tab`'s page, skipping the cache when `hard`.
    case reload(tab: String, hard: Bool)
    /// Loads `url` in tab `tab`.
    case go(tab: String, url: String)
    /// Moves tab `tab`'s page to `engine`.
    case engine(tab: String, engine: TerminalEngine)
    /// Moves tab `tab` to `space`, into `folder` there when given, and to
    /// where `place` says in its list.
    case move(tab: String, space: String?, folder: String?, place: TerminalPlace?)
    /// Pins tab `tab`, where `place` says among the pinned tabs.
    case pin(tab: String, place: TerminalPlace?)
    /// Saves tab `tab` to the sidebar's saved tabs, where `place` says.
    case save(tab: String, place: TerminalPlace?)
    /// Makes pinned or saved tab `tab` an open tab again, where `place` says.
    case unpin(tab: String, place: TerminalPlace?)
    /// Opens a copy of tab `tab` beside it.
    case duplicate(tab: String)
    /// Renames tab `tab`, or gives back its page's title when `title` is nil.
    case rename(tab: String, title: String?)
    /// Reopens the tab closed last.
    case reopen
}
