import SwiftUI

/// What the Forge adds for themes: the steps a page may limit it to, the
/// Other step's palette, popover and controls colors and theme file, and a
/// shuffle that keeps what the page doesn't edit.
extension BrowserCrestForge {
    // MARK: - Variables

    /// Whether this Forge edits the sidebar's colors and pattern.
    var offersSidebar: Bool { offeredSteps.contains(.sidebar) }

    /// Whether this Forge edits the crest or icon.
    var offersCrest: Bool {
        offeredSteps.contains { $0.isCrestOnly || $0 == .emblem }
    }

    /// The steps the step bar greys out: the crest's own, on an icon.
    var disabledSteps: Set<BrowserCrestStudioStep> {
        Set(offeredSteps.filter { branding.iconStyle == .simpleSymbol && $0.isCrestOnly })
    }

    /// What the Space dresses beyond its crest and sidebar: the command
    /// palette's card, its popovers, the address field and pins over the
    /// sidebar, then the look as a file to share. The stage heads the
    /// page as the galleries' do.
    @ViewBuilder
    var otherSections: some View {
        BrowserCrestStudioCommandPalette(context: context, isEmbedded: true) { stageHeader }
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

    /// The look shuffled in only what this Forge edits, keeping the crest or
    /// the sidebar it doesn't offer.
    func shuffledInOffer() -> SpaceBranding {
        var look = Self.shuffled(branding)
        if !offersSidebar {
            look.themeMode = branding.themeMode
            look.bannerPattern = branding.bannerPattern
            look.gradientAngle = branding.gradientAngle
            look.colors = branding.colors
        }
        if !offersCrest {
            look.crest = branding.crest
            look.iconStyle = branding.iconStyle
        }
        return look.normalized()
    }
}

/// The Sidebar step's sections after Crest's own: the Space's folders, and
/// the picture of the theme the Forge edits, when it edits one.
struct BrowserCrestForgeThemeSidebarSections: View {
    let context: BrowserCrestStudioContext

    @Environment(\.browserThemeForgeSubject) private var themeSubject

    var body: some View {
        BrowserCrestStudioFolders(context: context, isEmbedded: true)
        if let themeSubject {
            BrowserSpaceBackdropSection(target: themeSubject.backdrop)
        }
    }
}
