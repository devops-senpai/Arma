import Foundation

/// What the palette's tool scopes offer in this window: @extensions opens an
/// engine's extensions, @engine moves the shown page or its site to another
/// engine, @developer opens the page's developer tools, @cli sets up the
/// `arma` command, and @update checks for a new version.
extension BrowserCommandActions {
    // MARK: - Actions - Choices

    /// The choices of tool scope `scope`, built when the palette asks.
    func paletteChoices(in scope: PaletteScope, openSettings: @escaping (String) -> Void) -> [BrowserPaletteChoice] {
        let builders: [String: () -> [BrowserPaletteChoice]] = [
            PaletteScope.extensions.name: { extensionChoices(openSettings: openSettings) },
            PaletteScope.engine.name: engineChoices,
            PaletteScope.developer.name: developerChoices,
            PaletteScope.commandLine.name: commandLineChoices,
            PaletteScope.update.name: updateChoices,
        ]
        return builders[scope.name]?() ?? []
    }

    // MARK: - Actions - Extensions

    /// Each registered engine's extensions. WebKit takes none yet; when it
    /// does, its page joins here.
    private func extensionChoices(openSettings: @escaping (String) -> Void) -> [BrowserPaletteChoice] {
        let engines = browser.core.state.engines?.engines.map(\.kind) ?? []
        var choices: [BrowserPaletteChoice] = []
        if engines.contains(.chromium) {
            choices.append(
                BrowserPaletteChoice(
                    scope: .extensions, key: "chromium", name: String(localized: "Chromium Extensions"),
                    detail: "arma://extensions", symbol: "puzzlepiece.extension",
                    run: { openInChromium("arma://extensions") }))
            choices.append(
                BrowserPaletteChoice(
                    scope: .extensions, key: "chromeWebStore", name: String(localized: "Chrome Web Store"),
                    detail: String(localized: "Find extensions for Chromium"), symbol: "bag",
                    run: { openInChromium("https://chromewebstore.google.com") }))
            choices.append(
                BrowserPaletteChoice(
                    scope: .extensions, key: "spaceExtensions", name: String(localized: "Extension Settings"),
                    detail: String(localized: "Which Spaces run each extension, and what it may do"),
                    symbol: "gearshape", run: { openSettings("extensions") }))
        }
        if engines.contains(.servo) {
            choices.append(
                BrowserPaletteChoice(
                    scope: .extensions, key: "servo", name: String(localized: "Servo Extensions"),
                    detail: String(localized: "Firefox add-ons for Servo pages, in Settings › Engines"),
                    symbol: "puzzlepiece", run: { openSettings("engines") }))
        }
        return choices
    }

    /// Opens `address` in a new tab of the Space on screen, on Chromium.
    private func openInChromium(_ address: String) {
        guard let url = URL(string: address), browser.openNewTab(url: url) != nil else { return }
        pages.select()
        if let page = shownPage, page.corePage.state?.engine != .chromium {
            _ = page.corePage.move(to: .chromium)
        }
    }

    // MARK: - Actions - Engine

    /// For each engine the shown page is not on: move the page there, and
    /// open its site there from now on.
    private func engineChoices() -> [BrowserPaletteChoice] {
        guard let page = shownPage else { return [] }
        let origin = page.live.displayURL.flatMap(SiteOrigin.init(url:))
        let host = page.live.displayURL?.host()
        // Keeping the site on the engine it runs on now saves its rule
        // without moving the page.
        var keep: [BrowserPaletteChoice] = []
        if let origin, let host, let current = page.corePage.state?.engine {
            let title = String(localized: current.title)
            keep.append(
                BrowserPaletteChoice(
                    scope: .engine, key: "site-\(current.name)",
                    name: String(localized: "Always Open \(host) in \(title)"),
                    detail: String(localized: "This site's pages keep opening in \(title)"), symbol: "pin",
                    run: { _ = page.corePage.open(origin, in: page.spaceID, on: current) }))
        }
        return keep
            + page.corePage.otherEngines.flatMap { engine -> [BrowserPaletteChoice] in
                let title = String(localized: engine.title)
                var choices = [
                    BrowserPaletteChoice(
                        scope: .engine, key: "move-\(engine.name)", name: String(localized: "Open Page in \(title)"),
                        detail: String(localized: "Loads this page again in \(title)"), symbol: "arrow.triangle.swap",
                        run: { _ = page.corePage.move(to: engine) })
                ]
                if let origin, let host {
                    choices.append(
                        BrowserPaletteChoice(
                            scope: .engine, key: "site-\(engine.name)",
                            name: String(localized: "Always Open \(host) in \(title)"),
                            detail: String(localized: "This site's pages open in \(title) from now on"),
                            symbol: "pin", run: { _ = page.corePage.open(origin, in: page.spaceID, on: engine) }))
                }
                return choices
            }
    }

    // MARK: - Actions - Developer

    /// The page's developer tools, as the View menu offers them.
    private func developerChoices() -> [BrowserPaletteChoice] {
        [ShortcutCommand.showWebInspector, .toggleDeveloperToolbar].filter(canPerform).map { command in
            BrowserPaletteChoice(
                scope: .developer, key: command.name, name: command.title(locale: .current),
                detail: shownPage?.live.displayURL?.host() ?? "", symbol: command.symbol,
                run: { perform(command) })
        }
    }

    // MARK: - Actions - Update

    /// Checks for a new version, as the Arma menu's Check for Updates does.
    private func updateChoices() -> [BrowserPaletteChoice] {
        [
            BrowserPaletteChoice(
                scope: .update, key: "check", name: String(localized: "Check for Updates"),
                detail: String(localized: "Look for a new version and show it in the sidebar"),
                symbol: "arrow.down.circle", run: { [windows] in windows?.checkForUpdates() })
        ]
    }

    // MARK: - Actions - Command Line

    /// Whether `arma` is on the PATH, a way to put it there, and the lines
    /// to copy for a person who would rather do it in a terminal.
    private func commandLineChoices() -> [BrowserPaletteChoice] {
        let install = BrowserCommandLineInstall.shared
        install.readSearchPath()
        let helper = install.helper.path
        var choices: [BrowserPaletteChoice] = []
        if install.isTranslocated {
            choices.append(
                BrowserPaletteChoice(
                    scope: .commandLine, key: "translocated",
                    name: String(localized: "Move Arma to Applications First"),
                    detail: String(
                        localized: "macOS runs this copy from a temporary place, so a link to it would break"),
                    symbol: "exclamationmark.triangle", run: {}))
            return choices
        }
        switch install.presence {
        case .installed(let link):
            choices.append(
                BrowserPaletteChoice(
                    scope: .commandLine, key: "installed", name: String(localized: "arma Is Installed"),
                    detail: String(
                        localized: "\(BrowserCommandLineInstall.abbreviated(link)) runs this Arma; try arma --help"),
                    symbol: "checkmark.circle", run: { copy("arma --help") }))
        case .other(let found):
            choices.append(
                BrowserPaletteChoice(
                    scope: .commandLine, key: "other", name: String(localized: "Another arma Comes First"),
                    detail: String(localized: "\(BrowserCommandLineInstall.abbreviated(found)) is not this Arma's"),
                    symbol: "exclamationmark.triangle", run: { copy(found.path) }))
        case .absent:
            if let folder = install.userFolder {
                choices.append(
                    BrowserPaletteChoice(
                        scope: .commandLine, key: "install-\(folder)",
                        name: String(localized: "Install arma in \(folder)"),
                        detail: String(localized: "Links \(folder)/arma to this Arma"), symbol: "terminal",
                        run: { installCommandLine(into: folder) }))
                choices.append(
                    BrowserPaletteChoice(
                        scope: .commandLine, key: "copy-link", name: String(localized: "Copy Install Command"),
                        detail: install.linkCommand(into: folder), symbol: "doc.on.doc",
                        run: { copy(install.linkCommand(into: folder)) }))
            } else {
                choices.append(
                    BrowserPaletteChoice(
                        scope: .commandLine, key: "copy-setup",
                        name: String(localized: "Copy Command for ~/.local/bin"),
                        detail: String(localized: "Makes the folder, links arma there and adds it to zsh's PATH"),
                        symbol: "doc.on.doc", run: { copy(install.setUpCommand) }))
                choices.append(
                    BrowserPaletteChoice(
                        scope: .commandLine, key: "copy-sudo",
                        name: String(localized: "Copy Command for /usr/local/bin"),
                        detail: install.linkCommand(into: "/usr/local/bin"), symbol: "lock",
                        run: { copy(install.linkCommand(into: "/usr/local/bin")) }))
            }
        }
        choices.append(
            BrowserPaletteChoice(
                scope: .commandLine, key: "copy-path", name: String(localized: "Copy Path to arma"),
                detail: helper, symbol: "folder", run: { copy(helper) }))
        return choices
    }

    /// Links `arma` into `folder` and says how it went.
    private func installCommandLine(into folder: String) {
        guard let link = BrowserCommandLineInstall.shared.install(into: folder) else {
            chrome.showNotice(
                BrowserNotice(
                    message: String(localized: "Arma could not link arma into \(folder)"),
                    systemImage: "exclamationmark.triangle.fill"))
            return
        }
        chrome.showNotice(
            BrowserNotice(
                message: String(localized: "Installed \(BrowserCommandLineInstall.abbreviated(link)); try arma --help"),
                systemImage: "checkmark.circle.fill"))
    }
}
