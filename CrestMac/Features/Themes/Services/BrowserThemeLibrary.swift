import CryptoKit
import Foundation
import Observation

/// The themes on this Mac: the themes Arma ships with, and each theme a
/// person saved, a theme file in the format Export Theme writes, kept in
/// Arma's data folder under a name of its own. A bundled theme is saved as a
/// file of its own once it is edited.
///
/// The library lives in files rather than the core, so it neither syncs nor
/// travels with the session; a theme is put on a Space by copying its looks
/// into the Space's branding, as a house or scheme is. Which theme each Space
/// wears is this Mac's own too, beside its other appearance choices: a Space
/// that chose a theme wears it, and editing the theme, under Themes or from a
/// Space wearing it, dresses every Space wearing it.
@Observable
@MainActor
final class BrowserThemeLibrary {
    // MARK: - Types

    /// One saved theme: its file's identity, the name the list shows, and the
    /// looks it holds.
    struct Entry: Identifiable, Equatable {
        let id: UUID
        var theme: CrestTheme
        /// Whether this is a theme Arma ships with that was never saved as a
        /// file of its own.
        var isBundled = false

        var name: String { theme.name ?? String(localized: "Untitled Theme") }

        /// What the palette and the list show beneath the name.
        var detail: String {
            theme.hasDarkLook ? String(localized: "Light and dark looks") : String(localized: "One look")
        }
    }

    /// Which saved theme each Space wears, as the links file builds before
    /// the appearance defaults kept them wrote it.
    private struct Links: Codable, Equatable {
        /// Space to the theme it wears.
        var spaces: [UUID: UUID] = [:]
    }

    // MARK: - Static Variables

    /// The library of this launch's data folder.
    static let shared = BrowserThemeLibrary(directory: defaultDirectory(for: .current))

    /// How long edits rest before they are written and passed on, so a drag
    /// is one write rather than one for each sample.
    private static let settleDelay = Duration.milliseconds(400)

    /// Where this Mac keeps which theme each Space wears, beside its other
    /// appearance choices, and the theme new Spaces wear.
    static let spaceThemesKey = "arma.appearance.space-themes"
    static let defaultThemeKey = "arma.appearance.default-theme"

    // MARK: - Variables

    private(set) var entries: [Entry] = []
    private var links = Links()
    private let directory: URL?
    @ObservationIgnored private let defaults: UserDefaults

    /// The theme new Spaces wear, and Spaces that follow it, or nil for the
    /// look Crest gives them.
    private(set) var defaultThemeID: UUID?
    /// The pictures of the themes the Themes page edits, each kept under its
    /// theme's identity, as a Space's is under the Space's.
    let previewBackdrops = BrowserSpaceBackdropStore(
        directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("ArmaThemePreviews-\(UUID().uuidString)", isDirectory: true))
    @ObservationIgnored private var pendingThemeEdits: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var picturesToCapture: Set<UUID> = []
    /// The edits made on the Themes page, each a theme's run of changes
    /// until they rested, so Undo and Redo there step through them.
    @ObservationIgnored private let undoManager = UndoManager()
    /// Each theme as it was before the run of edits not yet rested.
    @ObservationIgnored private var themesBeforeEdits: [UUID: CrestTheme] = [:]
    @ObservationIgnored private var lastRestored: UUID?

    /// The saved themes as the command palette offers them.
    var paletteThemes: [PaletteTheme] {
        entries.map { PaletteTheme(id: $0.id, name: $0.name, detail: $0.detail) }
    }

    // MARK: - Initializers

    init(directory: URL?, defaults: UserDefaults = BrowserFolderAppearancePreference.defaults) {
        self.directory = directory
        self.defaults = defaults
        defaultThemeID = defaults.string(forKey: Self.defaultThemeKey).flatMap(UUID.init(uuidString:))
        reload()
        loadLinks()
        publishDefaultLook()
    }

    /// The installed app's Themes folder, or, for a review launch, one kept
    /// apart from it; a launch that keeps nothing keeps its themes in memory.
    static func defaultDirectory(for environment: BrowserLaunchEnvironment) -> URL? {
        guard
            var directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent(ProductIdentity.storageDirectoryName, isDirectory: true)
                .appendingPathComponent("Themes", isDirectory: true)
        else { return nil }
        if environment.requiresIsolation {
            guard let isolationID = environment.persistentIsolationID else { return nil }
            let namespace = SHA256.hash(data: Data(isolationID.utf8)).map { String(format: "%02x", $0) }.joined()
            directory = directory.appendingPathComponent("Isolated", isDirectory: true)
                .appendingPathComponent(namespace, isDirectory: true)
        }
        return directory
    }

    // MARK: - Actions - Reading

    func entry(_ id: UUID) -> Entry? {
        entries.first { $0.id == id }
    }

    /// The saved theme Space `spaceID` wears, or nil for a look of its own.
    func themeID(of spaceID: UUID) -> UUID? {
        guard let id = links.spaces[spaceID], entry(id) != nil else { return nil }
        return id
    }

    /// The Spaces of `browser` wearing the theme `id`.
    func spaces(wearing id: UUID, in browser: BrowserStore) -> [SpaceModel] {
        browser.spaceModels.filter { links.spaces[$0.id] == id }
    }

    /// The theme a Space wears now, named `name`.
    static func theme(of space: SpaceModel, named name: String) -> CrestTheme {
        var theme = CrestTheme(look: space.settings.look, dark: space.settings.darkBranding)
        theme.name = name
        theme.backgroundImage = backgroundImage(of: space.id, in: .shared)
        return theme
    }

    /// The picture `store` keeps under `ownerID`, with how it sits, as a
    /// theme carries it.
    static func backgroundImage(of ownerID: UUID, in store: BrowserSpaceBackdropStore) -> CrestTheme.BackgroundImage? {
        guard let backdrop = store.backdrop(for: ownerID), let image = store.imageData(for: ownerID) else {
            return nil
        }
        let backing = backdrop.tabBacking
        return CrestTheme.BackgroundImage(
            data: image.data.base64EncodedString(), format: image.format, anchor: backdrop.anchor.name,
            size: backdrop.size.name, growsToWidth: backdrop.growsToWidth, growsToHeight: backdrop.growsToHeight,
            tiles: backdrop.tiles, imageOpacity: backdrop.imageOpacity, tintOpacity: backdrop.tintOpacity,
            blur: backdrop.blur, tabBacking: backing.reach.name,
            tabBackingColor: backing.color.map(CrestTheme.text) ?? CrestTheme.defaultColorWord,
            tabBackingOpacity: backing.opacity, tabBackingBlur: backing.blur)
    }

    /// How a theme's picture sits, its unnamed choices at their defaults.
    private static func placement(of image: CrestTheme.BackgroundImage) -> BrowserSpaceBackdropStore.Backdrop {
        var backdrop = BrowserSpaceBackdropStore.Backdrop(file: "")
        backdrop.anchor = BrowserSpaceBackdropStore.Anchor.all.first { $0.name == image.anchor } ?? backdrop.anchor
        backdrop.size = BrowserSpaceBackdropStore.Size.all.first { $0.name == image.size } ?? backdrop.size
        backdrop.growsToWidth = image.growsToWidth ?? backdrop.growsToWidth
        backdrop.growsToHeight = image.growsToHeight ?? backdrop.growsToHeight
        backdrop.tiles = image.tiles ?? backdrop.tiles
        backdrop.imageOpacity = image.imageOpacity ?? backdrop.imageOpacity
        backdrop.tintOpacity = image.tintOpacity ?? backdrop.tintOpacity
        backdrop.blur = image.blur ?? backdrop.blur
        var backing = backdrop.tabBacking
        backing.reach =
            BrowserSpaceBackdropStore.TabBackingReach.all.first { $0.name == image.tabBacking } ?? backing.reach
        if let text = image.tabBackingColor { backing.color = (try? CrestTheme.color(text)) ?? nil }
        backing.opacity = image.tabBackingOpacity ?? backing.opacity
        backing.blur = image.tabBackingBlur ?? backing.blur
        backdrop.tabBacking = backing
        return backdrop
    }

    /// Gives `ownerID` in `store` the theme's picture, or takes its picture
    /// away when the theme has none.
    static func applyBackgroundImage(
        _ image: CrestTheme.BackgroundImage?, to ownerID: UUID, in store: BrowserSpaceBackdropStore
    ) throws {
        guard let image else {
            store.remove(for: ownerID)
            return
        }
        guard let data = Data(base64Encoded: image.data) else { throw CocoaError(.fileReadCorruptFile) }
        try store.setImage(data: data, format: image.format, placed: placement(of: image), for: ownerID)
    }

    /// `theme` without what belongs to a Space alone: its crest and icon,
    /// whose colors the Space keeps whatever theme it wears.
    static func withoutIdentity(_ theme: CrestTheme) -> CrestTheme {
        var theme = theme
        theme.look.symbolColor = nil
        theme.look.iconStyle = nil
        theme.dark?.symbolColor = nil
        theme.dark?.iconStyle = nil
        return theme
    }

    // MARK: - Actions - Applying

    /// Dresses the Space `spaceID` in the saved theme `id`, answering what
    /// went wrong, or nil once its looks changed.
    func apply(_ id: UUID, to spaceID: UUID, in browser: BrowserStore) -> String? {
        guard let entry = entry(id), let space = browser.spaceModel(spaceID) else {
            return String(localized: "That theme is no longer saved.")
        }
        let current = space.settings.look
        let currentDark = space.settings.darkBranding
        // The crest and icon keep the colors they wear now, in both looks.
        var identity = current
        identity.keepIdentityColors()
        do {
            var (look, dark) = try identity.dressed(in: Self.withoutIdentity(entry.theme), dark: currentDark)
            // A theme with one look takes away a dark look of the Space's own.
            if !entry.theme.hasDarkLook { dark = nil }
            dark = dark.map { dark in
                var dark = dark
                dark.crest = look.crest
                dark.iconStyle = look.iconStyle
                dark.symbolColor = look.symbolColor
                return dark
            }
            if look != current { browser.updateSpaceBranding(look.normalized(), in: spaceID) }
            if dark != currentDark { browser.updateSpaceDarkBranding(dark?.normalized(), in: spaceID) }
        } catch {
            return error.message
        }
        do {
            try Self.applyBackgroundImage(entry.theme.backgroundImage, to: spaceID, in: .shared)
        } catch {
            return String(localized: "The theme’s colors are on, but its background image could not be read.")
        }
        DiagnosticLog.themes.notice("Theme \(id) put on Space \(spaceID)")
        return nil
    }

    /// Dresses Space `spaceID` in the saved theme `id` and has it wear that
    /// theme from now on, answering what went wrong, or nil.
    func choose(_ id: UUID, for spaceID: UUID, in browser: BrowserStore) -> String? {
        if let problem = apply(id, to: spaceID, in: browser) { return problem }
        links.spaces[spaceID] = id
        saveLinks()
        return nil
    }

    /// Saves Space `space`'s look as a new theme named for it, which it wears
    /// from now on, answering the theme's identity.
    @discardableResult
    func saveAsTheme(_ space: SpaceModel) -> UUID {
        let id = add(Self.theme(of: space, named: space.settings.name))
        links.spaces[space.id] = id
        saveLinks()
        return id
    }

    /// Has Space `spaceID` wear no theme, keeping the look it has.
    func unlink(_ spaceID: UUID) {
        guard links.spaces.removeValue(forKey: spaceID) != nil else { return }
        saveLinks()
    }

    /// Gives Space `space`'s dark look the crest and icon `look` wears, so
    /// the Space shows one crest in light and dark windows.
    func keepDarkLookIdentity(of space: SpaceModel, as look: SpaceBranding, in browser: BrowserStore) {
        guard var dark = space.settings.darkBranding,
            dark.crest != look.crest || dark.iconStyle != look.iconStyle || dark.symbolColor != look.symbolColor
        else { return }
        dark.crest = look.crest
        dark.iconStyle = look.iconStyle
        dark.symbolColor = look.symbolColor
        browser.updateSpaceDarkBranding(dark.normalized(), in: space.id)
    }

    /// Dresses every Space wearing theme `id`, but `exception`, in it again.
    private func pass(_ id: UUID, on browser: BrowserStore, except exception: UUID? = nil) {
        for space in spaces(wearing: id, in: browser) where space.id != exception {
            _ = apply(id, to: space.id, in: browser)
        }
    }

    // MARK: - Actions - Default Theme

    /// Makes theme `id`, or none, the one new Spaces wear. Every Space of
    /// `browser` that followed the previous default, wearing it or wearing no
    /// theme in the look Crest started it with, wears the new one; with none,
    /// a Space that wore the previous default keeps its look, now its own.
    func chooseDefaultTheme(_ id: UUID?, in browser: BrowserStore? = nil) {
        let previous = defaultThemeID
        defaultThemeID = id.flatMap { entry($0) == nil ? nil : $0 }
        if let defaultThemeID {
            defaults.set(defaultThemeID.uuidString, forKey: Self.defaultThemeKey)
        } else {
            defaults.removeObject(forKey: Self.defaultThemeKey)
        }
        publishDefaultLook()
        guard let browser, !browser.isPrivateBrowsing, previous != defaultThemeID else { return }
        for space in browser.spaceModels {
            let worn = themeID(of: space.id)
            let follows =
                (previous != nil && worn == previous)
                || (worn == nil && space.settings.look.hasCustomAppearance != true)
            guard follows else { continue }
            if let defaultThemeID {
                _ = choose(defaultThemeID, for: space.id, in: browser)
            } else {
                unlink(space.id)
            }
        }
        DiagnosticLog.themes.notice("Default theme is \(defaultThemeID?.uuidString ?? "none")")
    }

    /// Hands the default theme's looks to the Spaces made from now on, and
    /// has each Space made in them wear the theme, its picture included: the
    /// looks carry the colors alone, and the picture sits in the backdrop
    /// store by Space.
    private func publishDefaultLook() {
        let shared = BrowserDefaultSpaceLook.shared
        guard let defaultThemeID, let theme = entry(defaultThemeID)?.theme,
            let (look, dark) = try? SpaceBranding.neutral.dressed(in: Self.withoutIdentity(theme), dark: nil)
        else {
            shared.look = nil
            shared.darkLook = nil
            shared.spaceMade = nil
            return
        }
        shared.look = look.normalized()
        shared.darkLook = dark?.normalized()
        shared.spaceMade = { [weak self] spaceID in
            guard let self, self.defaultThemeID == defaultThemeID else { return }
            self.links.spaces[spaceID] = defaultThemeID
            self.saveLinks()
            try? Self.applyBackgroundImage(theme.backgroundImage, to: spaceID, in: .shared)
        }
    }

    // MARK: - Actions - Editing

    /// Puts theme `id`'s picture, as `previewBackdrops` keeps it, ready to
    /// preview and edit.
    func preparePreview(_ id: UUID) {
        // A picture still being edited is newer in the preview than in the theme.
        guard let entry = entry(id), !picturesToCapture.contains(id) else { return }
        try? Self.applyBackgroundImage(entry.theme.backgroundImage, to: id, in: previewBackdrops)
    }

    /// Changes theme `id` now; once the edits rest it is written and every
    /// Space wearing it is dressed in it again.
    func edit(_ id: UUID, in browser: BrowserStore, _ change: (inout CrestTheme) -> Void) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        var theme = entries[index].theme
        change(&theme)
        theme.name = entries[index].theme.name
        guard theme != entries[index].theme else { return }
        if themesBeforeEdits[id] == nil { themesBeforeEdits[id] = entries[index].theme }
        entries[index].theme = theme
        settleThemeEdit(id, in: browser)
    }

    /// Notes that theme `id`'s picture changed in `previewBackdrops`; once
    /// the edits rest the theme carries it and its Spaces wear it.
    func pictureEdited(_ id: UUID, in browser: BrowserStore) {
        if themesBeforeEdits[id] == nil, let entry = entry(id) { themesBeforeEdits[id] = entry.theme }
        picturesToCapture.insert(id)
        settleThemeEdit(id, in: browser)
    }

    private func settleThemeEdit(_ id: UUID, in browser: BrowserStore) {
        pendingThemeEdits[id]?.cancel()
        pendingThemeEdits[id] = Task { [weak self, weak browser] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, let browser else { return }
            self.settle(id, in: browser)
        }
    }

    /// Writes theme `id`'s rested edits, dresses its Spaces in them, and
    /// keeps the run as one step Undo takes back.
    private func settle(_ id: UUID, in browser: BrowserStore) {
        pendingThemeEdits.removeValue(forKey: id)?.cancel()
        let before = themesBeforeEdits.removeValue(forKey: id)
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        if picturesToCapture.remove(id) != nil {
            entries[index].theme.backgroundImage = Self.backgroundImage(of: id, in: previewBackdrops)
        }
        write(entries[index])
        pass(id, on: browser)
        if let before, before != entries[index].theme { registerUndo(of: id, back: before, in: browser) }
    }

    // MARK: - Actions - Originals

    /// Theme `id` as it was installed or imported: a bundled theme as Arma
    /// ships it, a saved one as its file was first added.
    func original(of id: UUID) -> CrestTheme? {
        if let bundled = BrowserBundledTheme.named(id)?.theme { return bundled }
        guard let file = originalFile(for: id), let data = try? Data(contentsOf: file) else { return nil }
        return try? CrestTheme(json: data)
    }

    /// Whether theme `id` is still as it was installed or imported.
    func isOriginal(_ id: UUID) -> Bool {
        guard let entry = entry(id), let original = original(of: id) else { return true }
        return entry.theme == original
    }

    /// Puts theme `id` back as it was installed or imported, taking back
    /// every change made to it since, as one step Undo takes back in turn.
    /// Answers the theme, or nil when it was already so.
    func restoreOriginal(_ id: UUID, in browser: BrowserStore) -> UUID? {
        settleAll(in: browser)
        guard let entry = entry(id), let original = original(of: id), original != entry.theme else { return nil }
        restore(id, to: original, in: browser)
        DiagnosticLog.themes.notice("Theme \(id) restored to its original")
        return id
    }

    // MARK: - Actions - Undoing

    /// Takes back the last run of edits on the Themes page, answering the
    /// theme it changed, or nil when there was nothing to take back.
    func undo(in browser: BrowserStore) -> UUID? {
        settleAll(in: browser)
        guard undoManager.canUndo else { return nil }
        lastRestored = nil
        undoManager.undo()
        return lastRestored
    }

    /// Makes again the last run of edits Undo took back, answering the
    /// theme it changed, or nil when there was nothing to make again.
    func redo(in browser: BrowserStore) -> UUID? {
        settleAll(in: browser)
        guard undoManager.canRedo else { return nil }
        lastRestored = nil
        undoManager.redo()
        return lastRestored
    }

    /// Rests every edit still waiting, so Undo starts from the latest.
    private func settleAll(in browser: BrowserStore) {
        for id in Set(pendingThemeEdits.keys).union(themesBeforeEdits.keys) { settle(id, in: browser) }
    }

    private func registerUndo(of id: UUID, back theme: CrestTheme, in browser: BrowserStore) {
        undoManager.registerUndo(withTarget: self) { [weak browser] library in
            MainActor.assumeIsolated {
                guard let browser else { return }
                library.restore(id, to: theme, in: browser)
            }
        }
    }

    /// Puts theme `id` back as `theme` was, on its Spaces and its picture
    /// too, keeping how it is now for the opposite step.
    private func restore(_ id: UUID, to theme: CrestTheme, in browser: BrowserStore) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let current = entries[index].theme
        entries[index].theme = theme
        try? Self.applyBackgroundImage(theme.backgroundImage, to: id, in: previewBackdrops)
        write(entries[index])
        pass(id, on: browser)
        lastRestored = id
        registerUndo(of: id, back: current, in: browser)
        DiagnosticLog.themes.notice("Theme \(id) edit undone or redone")
    }

    // MARK: - Mutators

    /// Saves `theme` as a new entry, answering its identity.
    @discardableResult
    func add(_ theme: CrestTheme) -> UUID {
        let entry = Entry(id: UUID(), theme: theme)
        entries.append(entry)
        write(entry)
        keepOriginal(entry)
        sort()
        DiagnosticLog.themes.notice("Theme \(entry.id) saved")
        return entry.id
    }

    /// Saves a theme of the plain look, answering its identity.
    func addNew() -> UUID {
        add(CrestTheme(look: SpaceBranding.neutral).named(String(localized: "New Theme")))
    }

    /// Saves a copy of theme `id`, answering the copy's identity.
    func duplicate(_ id: UUID) -> UUID? {
        guard let entry = entry(id) else { return nil }
        return add(entry.theme.named(String(localized: "\(entry.name) Copy")))
    }

    /// Saves the theme file at `url` as a new entry, named for the file when
    /// it names nothing itself, answering its identity.
    func importFile(at url: URL) throws -> UUID {
        var theme = try CrestTheme(json: Data(contentsOf: url))
        if theme.name?.isEmpty ?? true { theme.name = url.deletingPathExtension().lastPathComponent }
        return add(theme)
    }

    /// Writes the entry `id` to `url` as a theme file.
    func export(_ id: UUID, to url: URL) throws {
        guard let entry = entry(id) else { return }
        try entry.theme.json().write(to: url, options: .atomic)
    }

    func rename(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].theme.name = trimmed
        write(entries[index])
        sort()
    }

    /// Replaces the looks of entry `id` with `theme`'s, keeping its name.
    func replaceLooks(of id: UUID, with theme: CrestTheme) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        var replaced = theme
        replaced.name = entries[index].theme.name
        entries[index].theme = replaced
        write(entries[index])
    }

    /// Turns theme `id`'s dark look on or off. Off keeps the look in the
    /// theme, so on brings it back as it was, or starts one from the light
    /// look the first time.
    func setDarkLook(_ id: UUID, on wanted: Bool, in browser: BrowserStore) {
        guard let entry = entry(id), entry.theme.hasDarkLook != wanted else { return }
        edit(id, in: browser) {
            $0.darkLook = wanted
            if wanted, $0.dark == nil { $0.dark = $0.look }
        }
    }

    /// Removes theme `id`, which no Space should wear any longer.
    func remove(_ id: UUID) {
        pendingThemeEdits.removeValue(forKey: id)?.cancel()
        themesBeforeEdits[id] = nil
        picturesToCapture.remove(id)
        entries.removeAll { $0.id == id }
        links.spaces = links.spaces.filter { $0.value != id }
        saveLinks()
        if defaultThemeID == id { chooseDefaultTheme(nil) }
        // A bundled theme the person deleted stays deleted.
        if BrowserBundledTheme.named(id) != nil { hideBundledTheme(id) }
        previewBackdrops.remove(for: id)
        DiagnosticLog.themes.notice("Theme \(id) removed")
        if let original = originalFile(for: id) { try? FileManager.default.removeItem(at: original) }
        guard let file = file(for: id) else { return }
        try? FileManager.default.removeItem(at: file)
    }

    /// Reads the folder again, keeping every file that holds a theme, and
    /// each bundled theme the person neither saved nor deleted.
    func reload() {
        var saved: [Entry] = []
        if let directory,
            let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        {
            saved = files.compactMap { file in
                guard file.pathExtension == "json",
                    let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                    let data = try? Data(contentsOf: file), let theme = try? CrestTheme(json: data)
                else { return nil }
                return Entry(id: id, theme: theme)
            }
        }
        let hidden = hiddenBundledThemes
        let bundled = BrowserBundledTheme.all.compactMap { bundled -> Entry? in
            guard !hidden.contains(bundled.id), !saved.contains(where: { $0.id == bundled.id }),
                let theme = bundled.theme
            else { return nil }
            return Entry(id: bundled.id, theme: theme, isBundled: true)
        }
        entries = saved + bundled
        sort()
        // A theme saved before originals were kept is taken as it is now.
        for entry in saved where BrowserBundledTheme.named(entry.id) == nil { keepOriginal(entry) }
    }

    /// The record of bundled themes the library has dealt with. A library
    /// from before bundled themes were offered in place saved a copy of each
    /// and noted it here, so one noted without a copy is one the person
    /// deleted.
    private var bundledRecord: URL? {
        directory?.appendingPathComponent("bundled.json", isDirectory: false)
    }

    private var hiddenBundledThemes: Set<UUID> {
        guard let bundledRecord, let data = try? Data(contentsOf: bundledRecord),
            let noted = try? JSONDecoder().decode(Set<UUID>.self, from: data)
        else { return [] }
        return noted.filter { id in file(for: id).map { !FileManager.default.fileExists(atPath: $0.path) } ?? true }
    }

    private func hideBundledTheme(_ id: UUID) {
        guard let directory, let bundledRecord else { return }
        var noted = (try? JSONDecoder().decode(Set<UUID>.self, from: Data(contentsOf: bundledRecord))) ?? []
        noted.insert(id)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(noted).write(to: bundledRecord, options: .atomic)
    }

    private var linksFile: URL? {
        directory?.appendingPathComponent("links.json", isDirectory: false)
    }

    /// Reads which theme each Space wears from the appearance defaults,
    /// moving the links file builds before them wrote there the first time.
    /// The file stays as it was, so an earlier build still reads it.
    private func loadLinks() {
        if let stored = defaults.dictionary(forKey: Self.spaceThemesKey) as? [String: String] {
            links.spaces = Dictionary(
                stored.compactMap { key, value in
                    guard let space = UUID(uuidString: key), let theme = UUID(uuidString: value) else { return nil }
                    return (space, theme)
                }, uniquingKeysWith: { first, _ in first })
            return
        }
        guard let linksFile, let data = try? Data(contentsOf: linksFile),
            let stored = try? JSONDecoder().decode(Links.self, from: data)
        else { return }
        links = stored
        saveLinks()
    }

    private func saveLinks() {
        defaults.set(
            Dictionary(uniqueKeysWithValues: links.spaces.map { ($0.key.uuidString, $0.value.uuidString) }),
            forKey: Self.spaceThemesKey)
    }

    private func sort() {
        entries.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func file(for id: UUID) -> URL? {
        directory?.appendingPathComponent(id.uuidString + ".json", isDirectory: false)
    }

    /// Where theme `id` is kept as it was installed or imported. Its name
    /// is no theme's identity, so `reload` passes it by.
    private func originalFile(for id: UUID) -> URL? {
        directory?.appendingPathComponent(id.uuidString + ".original.json", isDirectory: false)
    }

    /// Keeps `entry`'s theme as its original, unless one is kept already.
    private func keepOriginal(_ entry: Entry) {
        guard let directory, let file = originalFile(for: entry.id), !FileManager.default.fileExists(atPath: file.path)
        else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try entry.theme.json().write(to: file, options: .atomic)
        } catch {
            DiagnosticLog.themes.notice("Theme \(entry.id) original was not kept: \(DiagnosticLog.describe(error))")
        }
    }

    /// Writes `entry` as a version 2 theme file, saving a bundled theme as
    /// a file of its own the first time it changes.
    // MARK: - Mutators - Crests

    /// Keeps the crest Space `space` wears in theme `id` under `name`, made
    /// unique among the theme's crests, answering the name it took. The
    /// crest's colors go with it, so no theme redraws it.
    @discardableResult
    func keepCrest(of space: SpaceModel, named name: String, in id: UUID, browser: BrowserStore) -> String {
        guard let entry = entry(id) else { return name }
        let taken = Set((entry.theme.crests ?? []).map(\.name))
        var unique = name
        var count = 2
        while taken.contains(unique) {
            unique = "\(name) \(count)"
            count += 1
        }
        let look = space.settings.look
        let kept = CrestTheme.Crest(name: unique, crest: look.crest, in: look)
        edit(id, in: browser) { theme in theme.crests = (theme.crests ?? []) + [kept] }
        return unique
    }

    /// Renames the crest `name` theme `id` keeps to `newName`, unless the
    /// theme already keeps one by that name.
    func renameCrest(_ name: String, to newName: String, in id: UUID, browser: BrowserStore) {
        edit(id, in: browser) { theme in
            guard var crests = theme.crests, let index = crests.firstIndex(where: { $0.name == name }),
                !crests.contains(where: { $0.name == newName })
            else { return }
            crests[index].name = newName
            theme.crests = crests
        }
    }

    /// Drops the crest `name` from theme `id`.
    func removeCrest(named name: String, from id: UUID, browser: BrowserStore) {
        edit(id, in: browser) { theme in
            theme.crests?.removeAll { $0.name == name }
            if theme.crests?.isEmpty == true { theme.crests = nil }
        }
    }

    private func write(_ entry: Entry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) { entries[index].isBundled = false }
        if entry.id == defaultThemeID { publishDefaultLook() }
        guard let directory, let file = file(for: entry.id) else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try entry.theme.json().write(to: file, options: .atomic)
        } catch {
            DiagnosticLog.themes.notice("Theme \(entry.id) was not saved: \(DiagnosticLog.describe(error))")
        }
    }
}
