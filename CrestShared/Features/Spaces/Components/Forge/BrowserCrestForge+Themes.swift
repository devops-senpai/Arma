import SwiftUI

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
