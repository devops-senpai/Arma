import SwiftUI

// MARK: - Types

/// The theme a Space wears, offered first on its Appearance page: the themes
/// to choose from, No Theme among them, the one worn now, and a line under
/// the row for the other Spaces wearing it or what went wrong. A Space takes
/// its sidebar from its theme and shapes only its crest below, where the
/// theme's kept crests are offered by name beside the houses'.
struct BrowserSpaceThemeChoice {
    struct Option: Identifiable {
        /// The theme, or nil for No Theme.
        let id: UUID?
        let name: String
        let symbol: String
    }

    /// A crest the worn theme keeps, as the Space would wear it.
    struct Crest: Identifiable {
        var id: String { name }
        let name: String
        let crest: SpaceCrest
    }

    let options: [Option]
    let chosenID: UUID?
    let note: String?
    /// Dresses the Space in the theme, or in none for nil.
    let choose: (UUID?) -> Void
    /// The worn theme's kept crests, in the order kept.
    let crests: [Crest]
    /// Keeps the crest the Space wears in its theme under the name.
    let keepCrest: (String) -> Void
    /// Renames a kept crest, from the first name to the second.
    let renameCrest: (String, String) -> Void
    /// Drops a kept crest by name.
    let removeCrest: (String) -> Void
}

extension EnvironmentValues {
    /// The themes a Space's Appearance page offers, or nil where the app
    /// has none to offer.
    @Entry var browserSpaceThemeChoice: BrowserSpaceThemeChoice?
}

/// What the Forge adds for themes: a theme shown without a Space's icon, the
/// palette, popover and controls colors and theme file under More
/// Customization, and a shuffle that keeps what a theme doesn't carry.
extension BrowserCrestForge {
    // MARK: - Variables

    /// Whether the Forge edits a Space, with an icon and crest of its own,
    /// rather than a theme, which carries only what every Space wearing it
    /// shares.
    var offersIcon: Bool { themeSubject == nil }

    /// What the Space dresses beyond its crest and sidebar: the command
    /// palette's card, its popovers, the address field and pins over the
    /// sidebar, then the look as a file to share.
    @ViewBuilder
    var otherSections: some View {
        BrowserCrestStudioCommandPalette(context: context)
        BrowserCrestStudioPopoversAndControls(context: context)
        if let themeFiles {
            Section {
                Button("Export Theme…") { run(themeFiles.export) }
                Button("Load Theme from File…") { run(themeFiles.load) }
                if let themeFileProblem {
                    Text(themeFileProblem).font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text("Theme")
            }
        }
    }

    // MARK: - Actions

    /// Runs one theme file action and keeps what went wrong for the section.
    func run(_ action: @escaping @MainActor () async -> String?) {
        Task { @MainActor in themeFileProblem = await action() }
    }

    /// The look shuffled in what this Forge edits: a theme keeps the crest
    /// and icon of the Space it is shown on.
    func shuffledInOffer() -> SpaceBranding {
        var look = Self.shuffled(branding)
        if !offersIcon {
            look.crest = branding.crest
            look.iconStyle = branding.iconStyle
        }
        return look.normalized()
    }
}

/// The Sidebar sections after Crest's own: the Space's folders, and the
/// picture of the theme the Forge edits, when it edits one.
struct BrowserCrestForgeThemeSidebarSections: View {
    let context: BrowserCrestStudioContext

    @Environment(\.browserThemeForgeSubject) private var themeSubject

    var body: some View {
        BrowserCrestStudioFolders(context: context)
        if let themeSubject {
            BrowserSpaceBackdropSection(target: themeSubject.backdrop)
        }
    }
}

/// The Theme row heading a Space's Appearance page, where the app offers
/// themes: a menu of them, and under it who else wears the chosen one.
struct BrowserCrestForgeThemeSection: View {
    @Environment(\.browserSpaceThemeChoice) private var choice

    var body: some View {
        if let choice {
            Section {
                Picker("Theme", selection: Binding(get: { choice.chosenID }, set: choice.choose)) {
                    ForEach(choice.options) { option in
                        Label(option.name, systemImage: option.symbol).tag(option.id)
                    }
                }
                .accessibilityIdentifier("space-theme-picker")
            } footer: {
                if let note = choice.note {
                    Text(note)
                }
            }
        }
    }
}
