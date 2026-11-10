import Foundation

/// `arma tab`.
enum TerminalTabCommandLine: TerminalSection {
    static let name = "tab"
    static let summary = "List, open, close, move, pin and save tabs, and pick their engine"
    static let switches: Set<String> = ["loaded", "background", "hard", "pinned", "saved"]
    static let usage = """
        usage: arma tab <action> [options]

          list [--space <s>] [--folder <path>] [--loaded]
                                   tabs with their id, placement, folder, engine and
                                   whether their page is loaded, in the sidebar's order
          open <url> [--space <s>] [--engine chromium|webkit|servo] [--background]
                     [--pinned | --saved | --folder <path>] [--title <title>] [<place>]
                                   open a new tab; with no --space it opens in a Quick
                                   Window, where its Space menu picks the Space
          close <tab>              close a tab (a pinned or saved tab's page is put away)
          show <tab>               bring a tab forward
          reload <tab> [--hard]    reload, skipping the cache with --hard
          go <tab> <url>           load <url> in the tab
          engine <tab> <engine>    move the tab's page to chromium, webkit or servo
          move <tab> [--space <s>] [--folder <path>] [<place>]
                                   move a tab to another Space, into a folder, or to
                                   another place in its list
          pin <tab> | save <tab> | unpin <tab> [<place>]
                                   pin, save, or make it an open tab again
          duplicate <tab>          open a copy beside it
          rename <tab> [<title>]   rename, or go back to the page's title
          reopen                   reopen the tab closed last

        A tab is current (the front window's), its id, or the start of its id from
        arma tab list. A folder path joins folder names with /, such as Work/Clients.
        A <place> is --before <row>, --after <row> or --at <n>, where a row is a tab
        or a folder in the same list and <n> counts its rows from 1; without one the
        tab goes last.

        """

    static func command(action: String, _ arguments: inout TerminalArguments) throws(TerminalArguments.Problem)
        -> TerminalCommand
    {
        switch action {
        case "list", "ls":
            return .tab(
                .list(
                    space: arguments.option("space"), folder: arguments.option("folder"),
                    loadedOnly: arguments.has("loaded")))
        case "open", "new":
            let url = try arguments.take("an address")
            var engine: TerminalEngine?
            if let text = arguments.option("engine") {
                engine = try TerminalArguments.choice(text, as: TerminalEngine.self, for: "--engine")
            }
            let space = arguments.option("space")
            let folder = arguments.option("folder")
            var section: TerminalTabSection?
            if arguments.has("pinned") { section = .pinned }
            if arguments.has("saved") {
                guard section == nil else { throw TerminalArguments.Problem(message: "Give --pinned or --saved.") }
                section = .saved
            }
            if section != nil, folder != nil {
                throw TerminalArguments.Problem(message: "--folder picks the section; leave out --pinned and --saved.")
            }
            return .tab(
                .open(
                    url: url, space: space, engine: engine, background: arguments.has("background"), section: section,
                    folder: folder, place: try arguments.place(), title: arguments.option("title")))
        case "close":
            return .tab(.close(tab: try arguments.take("a tab")))
        case "show", "focus":
            return .tab(.show(tab: try arguments.take("a tab")))
        case "reload":
            return .tab(.reload(tab: try arguments.take("a tab"), hard: arguments.has("hard")))
        case "go", "navigate":
            let tab = try arguments.take("a tab")
            return .tab(.go(tab: tab, url: try arguments.take("an address")))
        case "engine":
            let tab = try arguments.take("a tab")
            let engine = try TerminalArguments.choice(
                try arguments.take("an engine"), as: TerminalEngine.self, for: "The engine")
            return .tab(.engine(tab: tab, engine: engine))
        case "move":
            let tab = try arguments.take("a tab")
            let space = arguments.option("space")
            let folder = arguments.option("folder")
            let place = try arguments.place()
            guard space != nil || folder != nil || place != nil else {
                throw TerminalArguments.Problem(message: "Give --space, --folder, a place, or several.")
            }
            return .tab(.move(tab: tab, space: space, folder: folder, place: place))
        case "pin":
            return .tab(.pin(tab: try arguments.take("a tab"), place: try arguments.place()))
        case "save":
            return .tab(.save(tab: try arguments.take("a tab"), place: try arguments.place()))
        case "unpin", "unsave":
            return .tab(.unpin(tab: try arguments.take("a tab"), place: try arguments.place()))
        case "duplicate":
            return .tab(.duplicate(tab: try arguments.take("a tab")))
        case "rename":
            let tab = try arguments.take("a tab")
            var words: [String] = []
            while let word = arguments.takeIfPresent() { words.append(word) }
            return .tab(.rename(tab: tab, title: words.isEmpty ? nil : words.joined(separator: " ")))
        case "reopen":
            return .tab(.reopen)
        default:
            throw TerminalArguments.Problem(message: "arma tab has no action '\(action)'.")
        }
    }
}
