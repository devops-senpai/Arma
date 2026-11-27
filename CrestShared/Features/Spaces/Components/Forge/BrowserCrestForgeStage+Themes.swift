import SwiftUI

/// What the stage adds for a theme: where the Forge edits a theme rather
/// than a Space, a small window in the theme's look in place of the crest.
extension BrowserCrestForgeStage {
    // MARK: - Actions - Theme

    /// A small window in the theme's look, where a Space's stage shows its
    /// crest, drawn in the appearance previewed. The stage around it is dark
    /// whatever the window is, so the preview says so itself.
    func themeStage(_ theme: BrowserThemeForgeSubject) -> some View {
        BrowserThemeStagePreview(
            branding: branding, symbol: theme.symbol, themeID: theme.backdrop.ownerID, backdrops: theme.backdrop.store
        )
        .environment(\.colorScheme, theme.appearance)
    }
}

extension View {
    // MARK: - Actions - Forge

    /// This view, or `replacement` while the Forge here edits a theme rather
    /// than a Space's own look.
    func replacedInThemeForge<Replacement: View>(
        @ViewBuilder _ replacement: @escaping (BrowserThemeForgeSubject) -> Replacement
    ) -> some View {
        modifier(BrowserThemeForgeReplacement(replacement: replacement))
    }
}

/// Swaps a part of the Forge's stage for what a theme's stage shows there.
private struct BrowserThemeForgeReplacement<Replacement: View>: ViewModifier {
    // MARK: - Variables

    let replacement: (BrowserThemeForgeSubject) -> Replacement
    @Environment(\.browserThemeForgeSubject) private var theme

    // MARK: - Body

    @ViewBuilder
    func body(content: Content) -> some View {
        if let theme {
            replacement(theme)
        } else {
            content
        }
    }
}
