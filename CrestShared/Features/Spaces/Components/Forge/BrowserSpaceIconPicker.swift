import SwiftUI

/// What a Space wears as its icon: a crest, or a plain symbol or emoji.
struct BrowserSpaceIconKind: Hashable, Identifiable, Sendable {
    // MARK: - Static Variables

    static let crest = BrowserSpaceIconKind(name: "crest", title: "Crest")
    static let symbol = BrowserSpaceIconKind(name: "symbol", title: "Symbol")
    static let emoji = BrowserSpaceIconKind(name: "emoji", title: "Emoji")

    static let all: [BrowserSpaceIconKind] = [crest, symbol, emoji]

    // MARK: - Variables

    let name: String
    let title: LocalizedStringResource

    var id: String { name }

    // MARK: - Initializers

    private init(name: String, title: LocalizedStringResource) {
        self.name = name
        self.title = title
    }

    // MARK: - Functions

    /// The kind of icon a Space wearing `branding` and `symbol` shows.
    static func worn(by branding: SpaceBranding, symbol: String) -> BrowserSpaceIconKind {
        if branding.iconStyle == .layeredCrest { return .crest }
        return BrowserIconSymbol.emoji(from: symbol) == nil ? .symbol : .emoji
    }

    // MARK: - Actions - Identity

    static func == (lhs: BrowserSpaceIconKind, rhs: BrowserSpaceIconKind) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/// A Space's icon: one of the houses' crests, one its theme keeps, or a
/// plain symbol or emoji. Choosing an icon never changes the Space's colors:
/// each crest comes in colors of its own while the Space's theme keeps the
/// sidebar. Setup's Space page and a Space's appearance in Settings both
/// show it; where the Space wears a theme, the theme's crests follow the
/// houses', with a tile that keeps the Space's own crest in the theme.
struct BrowserSpaceIconPicker: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding
    @Binding var symbol: String

    /// The kind picked, which may run ahead of the Space while a person
    /// chooses their first emoji.
    @State private var kind: BrowserSpaceIconKind?
    @State private var choosesEmoji = false
    @Environment(\.browserSpaceThemeChoice) private var themeChoice
    /// The name the theme group asks for, while it asks.
    @State private var naming: BrowserThemeCrestNaming?
    @State private var crestName = ""

    private var shownKind: BrowserSpaceIconKind {
        kind ?? BrowserSpaceIconKind.worn(by: branding, symbol: symbol)
    }

    // MARK: - Actions - Drawing

    var body: some View {
        Picker("Icon", selection: Binding(get: { shownKind }, set: choose)) {
            ForEach(BrowserSpaceIconKind.all) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityIdentifier("space-icon-kind")
        content
            .onChange(of: branding.iconStyle) { _, _ in kind = nil }
            .onChange(of: symbol) { _, _ in kind = nil }
    }

    @ViewBuilder private var content: some View {
        if shownKind == .crest {
            starterCrests
        } else if shownKind == .symbol {
            BrowserSystemSymbolPicker(
                selection: Binding(
                    get: { BrowserIconSymbol.emoji(from: symbol) == nil ? symbol : "" },
                    set: { wear($0) }))
        } else {
            emojiButton
        }
    }

    /// The houses' crests, simple then heraldic, each in the Space's colors:
    /// choosing one gives the Space that crest and nothing else.
    private var starterCrests: some View {
        VStack(alignment: .leading, spacing: BrowserSpaceIconPickerMetrics.styleSpacing) {
            ForEach(SpaceHouseStyle.all, id: \.self) { style in
                VStack(alignment: .leading, spacing: CrestSpacing.small) {
                    Text(style.title)
                        .crestCapsLabel()
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 80), spacing: CrestSpacing.small)],
                        spacing: CrestSpacing.small
                    ) {
                        ForEach(SpaceHouse.all.filter { $0.style == style }, id: \.self) { house in
                            crest(of: house)
                        }
                    }
                }
            }
            themeCrests
        }
        .padding(.vertical, CrestSpacing.extraSmall)
        .accessibilityIdentifier("space-starter-crests")
    }

    /// The crests the Space's theme keeps, each under its name with the one
    /// worn marked, and a tile that keeps the Space's own crest in the
    /// theme. A crest's menu renames it or drops it from the theme; the
    /// name is asked for in place.
    @ViewBuilder private var themeCrests: some View {
        if let themeChoice, themeChoice.chosenID != nil {
            VStack(alignment: .leading, spacing: CrestSpacing.small) {
                Text("Theme")
                    .crestCapsLabel()
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 80), spacing: CrestSpacing.small)],
                    spacing: CrestSpacing.small
                ) {
                    ForEach(themeChoice.crests) { kept in
                        themeCrest(kept, in: themeChoice)
                    }
                    if branding.iconStyle == .layeredCrest {
                        keepCrestTile(in: themeChoice)
                    }
                }
            }
            .accessibilityIdentifier("space-theme-crests")
            .crestPopover(item: $naming, arrowEdge: .bottom) { naming in
                namePrompt(naming, in: themeChoice)
            }
        }
    }

    /// Asks for the crest's name on the flyout surface: a field, Cancel and
    /// the one action, which Return also takes.
    private func namePrompt(_ naming: BrowserThemeCrestNaming, in choice: BrowserSpaceThemeChoice) -> some View {
        VStack(alignment: .leading, spacing: CrestSpacing.medium) {
            Text(naming.title)
                .font(.headline)
            TextField("Name", text: $crestName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .onSubmit { commit(naming, in: choice) }
                .accessibilityIdentifier("space-theme-crest-name")
            HStack {
                Spacer(minLength: 0)
                Button("Cancel", role: .cancel) { self.naming = nil }
                Button(naming.action) { commit(naming, in: choice) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(crestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(CrestSpacing.large)
    }

    private func themeCrest(_ kept: BrowserSpaceThemeChoice.Crest, in choice: BrowserSpaceThemeChoice) -> some View {
        let worn = branding.wearing(kept.crest)
        return BrowserCrestStudioChoice(
            title: "\(kept.name)", selected: branding.iconStyle == .layeredCrest && branding.crest == kept.crest
        ) {
            branding = worn
        } artwork: {
            BrowserSpaceCrestIcon(
                branding: worn, size: BrowserCrestForgeMetrics.tileCrestSize, rasterizesLayers: false
            )
            .equatable()
        }
        .contextMenu {
            Group {
                Button("Rename…", systemImage: "pencil") {
                    crestName = kept.name
                    naming = .rename(kept.name)
                }
                Button("Remove from Theme", systemImage: "trash", role: .destructive) { choice.removeCrest(kept.name) }
            }
            .crestMenuActionLabelStyle()
        }
        .accessibilityIdentifier("space-theme-crest-\(kept.name)")
    }

    /// Saves the crest the Space wears into its theme, under a name asked for
    /// in place, started from the house it came from, so every Space wearing
    /// the theme can pick it.
    private func keepCrestTile(in choice: BrowserSpaceThemeChoice) -> some View {
        BrowserCrestStudioChoice(title: "Add Current Crest…", selected: false) {
            crestName =
                SpaceHouse.startingPoint(of: branding).map { String(localized: $0.title) } ?? String(localized: "Crest")
            naming = .keep
        } artwork: {
            BrowserSpaceCrestIcon(
                branding: branding, size: BrowserCrestForgeMetrics.tileCrestSize, rasterizesLayers: false
            )
            .equatable()
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
            }
        }
        .help(Text("Add the crest this Space wears now to its theme, under a name, for every Space wearing the theme"))
        .accessibilityIdentifier("space-theme-crest-keep")
    }

    /// Keeps or renames a crest under the name typed, once there is one, and
    /// closes the prompt.
    private func commit(_ naming: BrowserThemeCrestNaming, in choice: BrowserSpaceThemeChoice) {
        let name = crestName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        switch naming {
        case .keep: choice.keepCrest(name)
        case .rename(let old): choice.renameCrest(old, name)
        }
        self.naming = nil
    }

    private func crest(of house: SpaceHouse) -> some View {
        let worn = branding.wearingCrest(of: house)
        return BrowserCrestStudioChoice(title: house.title, selected: branding.wearsCrest(of: house)) {
            branding = worn
        } artwork: {
            BrowserSpaceCrestIcon(
                branding: worn, size: BrowserCrestForgeMetrics.tileCrestSize, rasterizesLayers: false
            )
            .equatable()
        }
        .accessibilityIdentifier("space-icon-crest-\(house.name)")
    }

    private var emojiButton: some View {
        BrowserArtworkPickerButton(
            title: "Emoji",
            detail: BrowserIconSymbol.emoji(from: symbol) == nil ? Text("Choose an emoji") : Text("Change emoji")
        ) {
            choosesEmoji = true
        } artwork: {
            if let emoji = BrowserIconSymbol.emoji(from: symbol) {
                Text(emoji)
            } else {
                Image(systemName: "face.smiling")
            }
        }
        .accessibilityLabel("Choose Emoji")
        .browserIconCustomizationPopover(
            .init(
                isPresented: $choosesEmoji, title: "Space Icon",
                currentEmoji: BrowserIconSymbol.emoji(from: symbol),
                setEmoji: { wear(BrowserIconSymbol.symbol(forEmoji: $0)) }))
    }

    // MARK: - Mutators

    /// Shows `kind`: a crest at once, a symbol in place of an emoji, and the
    /// emoji picker for an emoji.
    private func choose(_ kind: BrowserSpaceIconKind) {
        if kind == .crest {
            self.kind = nil
            $branding.editorUpdate {
                $0.iconStyle = .layeredCrest
                $0.hasCustomAppearance = true
            }
        } else if kind == .symbol {
            self.kind = nil
            wear(BrowserIconSymbol.emoji(from: symbol) == nil ? symbol : BrowserSpaceIconPickerMetrics.symbol)
        } else {
            self.kind = kind
            choosesEmoji = true
        }
    }

    /// Gives the Space `symbol` as its plain icon.
    private func wear(_ symbol: String) {
        self.symbol = symbol
        guard branding.iconStyle != .simpleSymbol else { return }
        $branding.editorUpdate {
            $0.iconStyle = .simpleSymbol
            $0.hasCustomAppearance = true
        }
    }
}

/// What the theme group asks a name for: the Space's crest to keep, or a
/// kept crest to rename.
private enum BrowserThemeCrestNaming: Identifiable {
    case keep
    case rename(String)

    var id: String {
        switch self {
        case .keep: "keep"
        case .rename(let name): "rename-\(name)"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .keep: "Add Current Crest to Theme"
        case .rename: "Rename Crest"
        }
    }

    var action: LocalizedStringResource {
        switch self {
        case .keep: "Add"
        case .rename: "Rename"
        }
    }
}

enum BrowserSpaceIconPickerMetrics {
    /// The symbol a Space trading its emoji for a symbol starts from.
    static let symbol = "sparkles"
    /// The room between the simple and heraldic crests, and under each name.
    static let styleSpacing: CGFloat = 14
}

#if DEBUG
    #Preview("Space icon") {
        @Previewable @State var branding = SpaceHouse.winter.look
        @Previewable @State var symbol = "briefcase.fill"
        Form {
            Section {
                BrowserSpaceIconPicker(branding: $branding, symbol: $symbol)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
    }
#endif
