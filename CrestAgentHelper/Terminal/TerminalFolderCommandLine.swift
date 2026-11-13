import Foundation

/// `arma folder`.
enum TerminalFolderCommandLine: TerminalSection {
    static let name = "folder"
    static let summary = "List, create, rename, move, delete and color folders, and file tabs in them"
    static let switches: Set<String> = ["open", "saved", "top"]
    static let usage = """
        usage: arma folder <action> [options]

          list [--space <s>]       folders as a tree, in the saved and open sections,
                                   with the tabs each holds
          create <name> [--space <s>] [--in <path>] [--open] [<place>]
                                   make a folder, inside <path> when given; saved,
                                   or in the open tabs with --open
          rename <path> <name> [--space <s>]
                                   rename a folder
          move <path> [--space <s>] [--in <path> | --top] [--saved | --open] [<place>]
                                   move a folder, with everything in it, inside another
                                   folder or to the top level, to the saved or open
                                   tabs, or to another place among its neighbours
          delete <path> [--space <s>]
                                   delete a folder; its tabs stay in its section and
                                   the folders inside it move up one level
          add <tab>... --to <path> [--space <s>] [<place>]
                                   file tabs into a folder
          open <path> | close <path> [--space <s>]
                                   expand or collapse a folder in the sidebar
          color <path> <#hex|default> [--space <s>]
                                   give a folder its own color, or its Space's again

        A folder path joins folder names with /, such as Work/Clients; one name is
        enough when no other folder has it. Without --space, the front window's
        Space. A tab is current, its id, or the start of its id from arma tab list.
        A <place> is --before <row>, --after <row> or --at <n>, where a row is a tab
        or a folder in the same list and <n> counts its rows from 1; without one the
        folder or tabs go last.

        """

    static func command(action: String, _ arguments: inout TerminalArguments) throws(TerminalArguments.Problem)
        -> TerminalCommand
    {
        let space = arguments.option("space")
        switch action {
        case "list", "ls":
            return .folder(.list(space: space))
        case "create", "new":
            let name = try words(&arguments, naming: "a name")
            return .folder(
                .create(
                    name: name, space: space, parent: arguments.option("in"), open: arguments.has("open"),
                    place: try arguments.place()))
        case "rename":
            let folder = try arguments.take("a folder")
            return .folder(.rename(folder: folder, name: try words(&arguments, naming: "a new name"), space: space))
        case "move", "mv":
            let folder = try arguments.take("a folder")
            let parent = arguments.option("in")
            let top = arguments.has("top")
            guard parent == nil || !top else {
                throw TerminalArguments.Problem(message: "Give --in <path> or --top, not both.")
            }
            var section: TerminalFolderSection?
            if arguments.has("saved") { section = .saved }
            if arguments.has("open") {
                guard section == nil else { throw TerminalArguments.Problem(message: "Give --saved or --open.") }
                section = .open
            }
            let place = try arguments.place()
            guard parent != nil || top || section != nil || place != nil else {
                throw TerminalArguments.Problem(message: "Say where: --in <path>, --top, --saved, --open or a place.")
            }
            return .folder(
                .move(folder: folder, space: space, parent: parent, top: top, section: section, place: place))
        case "delete", "remove", "rm":
            return .folder(.delete(folder: try arguments.take("a folder"), space: space))
        case "add", "file":
            guard let folder = arguments.option("to") else {
                throw TerminalArguments.Problem(message: "Give the folder with --to.")
            }
            var tabs = [try arguments.take("a tab")]
            while let tab = arguments.takeIfPresent() { tabs.append(tab) }
            return .folder(.add(tabs: tabs, folder: folder, space: space, place: try arguments.place()))
        case "open", "expand":
            return .folder(.expand(folder: try arguments.take("a folder"), space: space, expanded: true))
        case "close", "collapse":
            return .folder(.expand(folder: try arguments.take("a folder"), space: space, expanded: false))
        case "color", "colour":
            let folder = try arguments.take("a folder")
            let color = try arguments.take("a color, as #RRGGBB or default")
            let isDefault = ["default", "none", "space"].contains(color.lowercased())
            return .folder(.color(folder: folder, hex: isDefault ? nil : color, space: space))
        default:
            throw TerminalArguments.Problem(message: "arma folder has no action '\(action)'.")
        }
    }

    /// The words left, as one name.
    private static func words(
        _ arguments: inout TerminalArguments, naming name: String
    ) throws(TerminalArguments.Problem) -> String {
        var words = [try arguments.take(name)]
        while let word = arguments.takeIfPresent() { words.append(word) }
        return words.joined(separator: " ")
    }
}
