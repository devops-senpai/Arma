import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Settings › Themes: the themes saved on this Mac in a list, with buttons
/// beneath it to make, copy and remove one and bring theme files in and out;
/// beside it the chosen theme's name, its dark look, and the Forge's sidebar
/// steps with its picture and tab backing. Editing a theme here edits that
/// theme, and dresses every Space wearing it again. While the page is shown
/// the windows draw in the appearance it previews, so a dark look can be made
/// on a light Mac.
struct BrowserThemesSettingsPane: View {
    // MARK: - Variables

    let browser: BrowserStore

    @State private var library = BrowserThemeLibrary.shared
    @State private var selection: UUID?
    @State private var name = ""
    /// The appearance the page previews the theme in: the windows draw in it
    /// while the page is shown, and a theme with both looks is edited in the
    /// look worn then.
    @State private var previewScheme: ColorScheme = .light
    @State private var step = BrowserCrestStudioStep.sidebar
    /// The theme waiting on the person to confirm its removal.
    @State private var notice: String?
    /// What the list button under the pointer does, named between the buttons.
    @State private var hoveredAction: LocalizedStringKey?

    @Environment(\.colorScheme) private var colorScheme

    /// The steps that edit what a theme carries.
    private static let themeSteps: [BrowserCrestStudioStep] = [.start, .sidebar, .other]

    private var selected: BrowserThemeLibrary.Entry? {
        selection.flatMap(library.entry)
    }

    // MARK: - Actions - Presentation

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            list
                .frame(width: 200)
                .padding(CrestSpacing.large)
            Divider()
            editor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            BrowserThemeUndoKeys(
                undo: { show(library.undo(in: browser)) }, redo: { show(library.redo(in: browser)) })
        }
        // Opening Themes selects the theme the shown Space wears, and
        // previews it as the window is.
        .onAppear {
            selection = shownSpaceThemeID ?? selection ?? library.entries.first?.id
            previewScheme = colorScheme
            BrowserMacAppearance.shared.preview = previewScheme
        }
        .onDisappear { BrowserMacAppearance.shared.preview = nil }
        .onChange(of: previewScheme) { BrowserMacAppearance.shared.preview = previewScheme }
        .onChange(of: selection, initial: true) { previous, _ in
            if let previous { commitName(of: previous) }
            name = selected?.name ?? ""
            if let selection { library.preparePreview(selection) }
        }
        .accessibilityIdentifier("settings-form-themes")
    }

    /// Selects theme `id`, which Undo or Redo just changed, answering
    /// whether there was one.
    private func show(_ id: UUID?) -> Bool {
        guard let id else { return false }
        selection = id
        library.preparePreview(id)
        return true
    }

    // MARK: - List

    private var list: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List(library.entries, selection: $selection) { entry in
                    HStack(spacing: CrestSpacing.small) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                            Text(subtitle(of: entry)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        if entry.id == shownSpaceThemeID {
                            Image(systemName: "star.fill")
                                .help("The theme of the Space this window shows")
                                .accessibilityLabel("Theme of the shown Space")
                        }
                    }
                    .tag(entry.id)
                }
                .listStyle(.bordered)
                // Double-clicking a theme puts it on the Space this window shows.
                .contextMenu(forSelectionType: UUID.self) { ids in
                    if let id = ids.first {
                        Group {
                            if let shownSpaceName {
                                Button("Use for \(shownSpaceName)", systemImage: "checkmark.circle") {
                                    useForShownSpace(id)
                                }
                                .disabled(id == shownSpaceThemeID)
                                Divider()
                            }
                            Button("Duplicate", systemImage: "plus.square.on.square") { duplicate(id) }
                            Button("Export Theme…", systemImage: "square.and.arrow.up") { export(id) }
                            Divider()
                            Button("Delete Theme", systemImage: "trash", role: .destructive) { requestRemoval(id) }
                        }
                        .crestMenuActionLabelStyle()
                    }
                } primaryAction: { ids in
                    ids.first.map(useForShownSpace)
                }
                .onChange(of: selection, initial: true) { _, selected in if let selected { proxy.scrollTo(selected) } }
            }
            .overlay {
                if library.entries.isEmpty {
                    Text("No Saved Themes").foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 0) {
                glyph("plus", label: "New Theme") { selection = library.addNew() }
                glyph("plus.square.on.square", label: "Duplicate Theme") { selection.map(duplicate) }
                    .disabled(selection == nil)
                glyph("minus", label: "Delete Theme") { selection.map(requestRemoval) }
                    .disabled(selection == nil)
                glyph("checkmark.circle", label: "Use for \(shownSpaceName ?? "This Space")") {
                    selection.map(useForShownSpace)
                }
                .disabled(selection == nil || selection == shownSpaceThemeID || shownSpaceName == nil)
                Spacer(minLength: CrestSpacing.small)
                if let hoveredAction {
                    Text(hoveredAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: CrestSpacing.small)
                glyph("square.and.arrow.down", label: "Import Theme…") { importFiles() }
                glyph("square.and.arrow.up", label: "Export Theme…") { selection.map(export) }
                    .disabled(selection == nil)
            }
            .padding(.top, CrestSpacing.small)
            if let notice {
                Text(notice).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, CrestSpacing.small)
            }
        }
    }

    /// The theme the Space this window shows wears, which the list stars.
    private var shownSpaceThemeID: UUID? {
        library.themeID(of: browser.selectedSpaceID)
    }

    /// The name of the Space this window shows, which Use for puts a theme on.
    private var shownSpaceName: String? {
        browser.spaceModel(browser.selectedSpaceID)?.settings.name
    }

    /// Puts theme `id` on the Space this window shows.
    private func useForShownSpace(_ id: UUID) {
        notice = library.choose(id, for: browser.selectedSpaceID, in: browser)
    }

    /// The Spaces wearing a theme, or what looks it holds when none does.
    private func subtitle(of entry: BrowserThemeLibrary.Entry) -> String {
        let spaces = library.spaces(wearing: entry.id, in: browser)
        return spaces.isEmpty ? entry.detail : spaces.map(\.settings.name).formatted(.list(type: .and))
    }

    private func wearers(of id: UUID) -> String {
        library.spaces(wearing: id, in: browser).map(\.settings.name).formatted(.list(type: .and))
    }

    private func glyph(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(CrestChromeButtonStyle())
        .help(label)
        .accessibilityLabel(label)
        .onHover { inside in
            if inside {
                hoveredAction = label
            } else if hoveredAction == label {
                hoveredAction = nil
            }
        }
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        if let entry = selected {
            VStack(spacing: 0) {
                header(entry)
                BrowserCrestForge(
                    branding: editsDark(entry) ? darkLook(entry.id) : lightLook(entry.id),
                    symbol: .constant(baseSpace?.settings.symbol ?? "paintpalette"), step: $step,
                    offeredSteps: Self.themeSteps
                )
                .id("\(entry.id)-\(editsDark(entry))")
                .environment(\.browserSpaceSidebarSections, backdropSections(entry.id))
                .environment(\.browserCrestForgeStageHero, stagePreview(entry.id))
            }
        } else {
            Text("Choose a theme, or make a new one.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func header(_ entry: BrowserThemeLibrary.Entry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                    .onSubmit { commitName(of: entry.id) }
                Toggle("Dark look", isOn: hasDarkLook(entry.id))
                    .toggleStyle(.switch)
                    .fixedSize()
                    .help("Give this theme a look of its own while windows are dark")
                Spacer(minLength: 0)
                Picker("Appearance preview", selection: $previewScheme) {
                    Text("Light").tag(ColorScheme.light)
                    Text("Dark").tag(ColorScheme.dark)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .help("Draw the windows light or dark while this page is open")
            }
            let spaces = library.spaces(wearing: entry.id, in: browser)
            if !spaces.isEmpty {
                Text("Used by \(spaces.map(\.settings.name).formatted(.list(type: .and)))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: BrowserCrestForgeMetrics.columnWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, BrowserSettingsLayout.formMinimumInset)
        .padding(.vertical, 10)
    }

    // MARK: - Looks

    /// The Space whose crest the editor shows the theme on: one wearing it,
    /// else the one the window shows.
    private var baseSpace: SpaceModel? {
        selection.flatMap { library.spaces(wearing: $0, in: browser).first }
            ?? browser.spaceModel(browser.selectedSpaceID)
    }

    private var baseLook: SpaceBranding {
        baseSpace?.settings.look ?? .neutral
    }

    /// Theme `id`'s light look on the base Space's crest; editing it edits the theme.
    private func lightLook(_ id: UUID) -> Binding<SpaceBranding> {
        Binding(
            get: { shownLight(id) },
            set: { look in library.edit(id, in: browser) { $0.sections = CrestTheme.Sections(look: look) } })
    }

    /// Theme `id`'s dark look, started from its light one.
    private func darkLook(_ id: UUID) -> Binding<SpaceBranding> {
        Binding(
            get: {
                let light = shownLight(id)
                guard let dark = library.entry(id)?.theme.dark else { return light }
                return (try? light.dressed(in: dark)) ?? light
            },
            set: { look in library.edit(id, in: browser) { $0.dark = CrestTheme.Sections(look: look) } })
    }

    private func shownLight(_ id: UUID) -> SpaceBranding {
        guard let theme = library.entry(id)?.theme else { return baseLook }
        return (try? baseLook.dressed(in: theme.sections)) ?? baseLook
    }

    /// Whether the controls edit `entry`'s dark look: the one worn in the
    /// appearance previewed, when the theme has it.
    private func editsDark(_ entry: BrowserThemeLibrary.Entry) -> Bool {
        previewScheme == .dark && entry.theme.hasDarkLook
    }

    /// Whether theme `id` wears a dark look: turning it off keeps the look in
    /// the theme, turning it on brings it back, or starts one from the light look.
    private func hasDarkLook(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { library.entry(id)?.theme.hasDarkLook ?? false },
            set: { wanted in library.setDarkLook(id, on: wanted, in: browser) })
    }

    /// A small window in theme `id`'s look, where a Space's Forge shows its
    /// crest, drawn in the appearance previewed. The stage around it is dark
    /// whatever the window is, so the preview says so itself.
    private func stagePreview(_ id: UUID) -> BrowserCrestForgeStageHero {
        let symbol = baseSpace?.settings.symbol ?? "paintpalette"
        let appearance = previewScheme
        return BrowserCrestForgeStageHero { [library] branding in
            AnyView(
                BrowserThemeStagePreview(
                    branding: branding, symbol: symbol, themeID: id, backdrops: library.previewBackdrops
                )
                .environment(\.colorScheme, appearance))
        }
    }

    private func backdropSections(_ id: UUID) -> BrowserSpaceSidebarSections {
        let target = BrowserSpaceBackdropSection.Target(
            store: library.previewBackdrops, ownerID: id, branding: shownLight(id),
            changed: { [library, browser] in library.pictureEdited(id, in: browser) })
        return BrowserSpaceSidebarSections { AnyView(BrowserSpaceBackdropSection(target: target)) }
    }

    // MARK: - Mutators

    private func commitName(of id: UUID) {
        guard let entry = library.entry(id), name != entry.name else { return }
        library.rename(id, to: name)
    }

    private func duplicate(_ id: UUID) {
        if let copy = library.duplicate(id) { selection = copy }
    }

    /// Removes theme `id`, unless a Space wears it: every Space wears a
    /// theme, so its Spaces pick another first.
    private func requestRemoval(_ id: UUID) {
        guard library.entry(id) != nil else { return }
        guard library.spaces(wearing: id, in: browser).isEmpty else {
            notice = String(localized: "\(wearers(of: id)) uses this theme; choose another for it first.")
            return
        }
        notice = nil
        library.remove(id)
        if selection == id { selection = library.entries.first?.id }
    }

    private func importFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        var last: UUID?
        for url in panel.urls {
            last = (try? library.importFile(at: url)) ?? last
        }
        notice = last == nil ? String(localized: "That file is not an Arma theme.") : nil
        if let last { selection = last }
    }

    private func export(_ id: UUID) {
        guard let entry = library.entry(id) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(entry.name).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try library.export(id, to: url) } catch { notice = error.localizedDescription }
    }
}
