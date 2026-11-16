import CryptoKit
import Foundation

// MARK: - Types

/// Something the shell can do from one of the palette's tool scopes, such as
/// @engine: the scope, what its row says and wears, and what it does. Its
/// identity comes from the scope and `key`, so the row the core ranked finds
/// the same choice when it is picked.
struct BrowserPaletteChoice {
    let scope: PaletteScope
    let key: String
    let name: String
    let detail: String
    let symbol: String
    let run: @MainActor () -> Void
    /// Whether running it leads to more choices, which the palette shows in
    /// its place, rather than closing the palette.
    var stepsInto = false

    var id: UUID {
        let digest = Array(SHA256.hash(data: Data("\(scope.name)/\(key)".utf8)))
        return UUID(
            uuid: (
                digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
                digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]
            ))
    }

    /// The choice as the core ranks it.
    var paletteChoice: PaletteChoice {
        PaletteChoice(id: id, scope: scope, name: name, detail: detail, symbol: symbol, stepsInto: stepsInto)
    }
}

/// Commands, settings pages and the window's own actions, supplied by the
/// presenting platform shell, which palette rows other than addresses and
/// tabs perform.
@MainActor
struct BrowserCommandPaletteCommandRegistry {
    let commands: [ShortcutCommand]
    /// The settings pages the palette may open, by their settings name.
    let settingsPages: [PaletteSettingsPage]
    /// The saved themes the palette may put on the Space, read when asked.
    let themes: () -> [PaletteTheme]
    private let shortcutProvider: (ShortcutCommand) -> BrowserShortcut?
    private let performer: (ShortcutCommand) -> Void
    private let settingsOpener: (String) -> Void
    private let spaceSwitcher: (UUID) -> Void
    private let archiveReopener: (UUID) -> Void
    private let copier: (String) -> Void
    private let themeApplier: (UUID) -> Void
    private let choiceProvider: (PaletteScope) -> [BrowserPaletteChoice]
    private let choiceStepBack: (PaletteScope) -> Bool

    init(
        commands: [ShortcutCommand],
        settingsPages: [PaletteSettingsPage] = [],
        shortcut: @escaping (ShortcutCommand) -> BrowserShortcut? = { _ in nil },
        perform: @escaping (ShortcutCommand) -> Void,
        openSettings: @escaping (String) -> Void = { _ in },
        switchSpace: @escaping (UUID) -> Void = { _ in },
        reopenArchivedTab: @escaping (UUID) -> Void = { _ in },
        copy: @escaping (String) -> Void = { _ in },
        themes: @escaping () -> [PaletteTheme] = { [] },
        applyTheme: @escaping (UUID) -> Void = { _ in },
        choices: @escaping (PaletteScope) -> [BrowserPaletteChoice] = { _ in [] },
        stepBack: @escaping (PaletteScope) -> Bool = { _ in false }
    ) {
        self.commands = commands
        self.settingsPages = settingsPages
        shortcutProvider = shortcut
        performer = perform
        settingsOpener = openSettings
        spaceSwitcher = switchSpace
        archiveReopener = reopenArchivedTab
        copier = copy
        self.themes = themes
        themeApplier = applyTheme
        choiceProvider = choices
        choiceStepBack = stepBack
    }

    /// The commands as the palette ranks them, with the titles this device
    /// shows for them.
    var paletteCommands: [PaletteCommand] {
        commands.map {
            PaletteCommand(
                command: $0, title: $0.title(locale: .current), sectionTitle: $0.section.title(locale: .current))
        }
    }

    func shortcut(for command: ShortcutCommand) -> BrowserShortcut? {
        shortcutProvider(command)
    }

    func perform(_ command: ShortcutCommand) {
        performer(command)
    }

    /// Opens Settings at the page the settings call `name`.
    func openSettings(_ name: String) {
        settingsOpener(name)
    }

    func switchSpace(_ id: UUID) {
        spaceSwitcher(id)
    }

    func reopenArchivedTab(_ id: UUID) {
        archiveReopener(id)
    }

    /// Puts the saved theme `id` on the Space the window shows.
    func applyTheme(_ id: UUID) {
        themeApplier(id)
    }

    /// What the shell can do from tool scope `scope`, as the core ranks it.
    func choices(in scope: PaletteScope) -> [PaletteChoice] {
        choiceProvider(scope).map(\.paletteChoice)
    }

    /// Does the choice `id` of tool scope `scope`, answering whether it was there.
    func runChoice(_ id: UUID, in scope: PaletteScope) -> Bool {
        guard let choice = choiceProvider(scope).first(where: { $0.id == id }) else { return false }
        choice.run()
        return true
    }

    /// Steps back out of a choice tool scope `scope` stepped into, such as a
    /// saved login, answering whether there was one to leave.
    func stepBack(in scope: PaletteScope) -> Bool {
        choiceStepBack(scope)
    }

    /// Copies `text` and says so in the window's notice.
    func copy(_ text: String) {
        copier(text)
    }
}
