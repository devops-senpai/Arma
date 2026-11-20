import SwiftUI

/// What the stage adds for a theme: the sidebar's text colors beside its
/// field's, and, where the Forge edits a theme rather than a Space, a small
/// window in the theme's look in place of the crest.
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

    // MARK: - Actions - Text colors

    func textSwatch(_ text: BrowserCrestForgeTextColor, columnWidth: CGFloat) -> some View {
        let color = text.color(in: branding, over: .dark)
        return BrowserCrestForgeSwatch(
            title: text.title, fill: CrestColorFill(color), isOpen: openTextColor == text.id, columnWidth: columnWidth
        ) {
            openTextColor = text.id
        }
        .crestPopover(
            isPresented: Binding(
                get: { openTextColor == text.id }, set: { if !$0, openTextColor == text.id { openTextColor = nil } }),
            arrowEdge: .bottom
        ) {
            BrowserColorWheelPicker(
                color: Binding(
                    get: { color },
                    set: { picked in
                        branding[keyPath: text.keyPath] = picked
                        branding = branding.normalized()
                    }), title: LocalizedStringKey(String(localized: text.title))
            )
            .presentationCompactAdaptation(.popover)
        }
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

/// One of the sidebar's text colors the stage offers beside its field's:
/// the tabs' text, and the quieter system text such as New Tab and Clear.
struct BrowserCrestForgeTextColor: Identifiable, Sendable {
    // MARK: - Static Variables

    static let tabs = BrowserCrestForgeTextColor(
        id: "tabs", title: "Tab text", caption: "The color of the tabs' titles",
        keyPath: \.sidebarTextColor, emphasis: 1)
    static let system = BrowserCrestForgeTextColor(
        id: "system", title: "System text", caption: "New Tab, Clear and the sidebar's other quieter text",
        keyPath: \.sidebarSecondaryTextColor, emphasis: 0.6)
    static let all = [tabs, system]

    // MARK: - Variables

    let id: String
    let title: LocalizedStringResource
    let caption: LocalizedStringResource
    let keyPath: WritableKeyPath<SpaceBranding, BrandColor?> & Sendable
    /// How strongly the text color shows where this one follows it.
    let emphasis: Double

    // MARK: - Actions - Colors

    /// The color it draws in `branding` over a window in `appearance`: its
    /// own, or the tab text faded as the system fades it.
    func color(in branding: SpaceBranding, over appearance: ColorScheme) -> BrandColor {
        if let own = branding[keyPath: keyPath] { return own }
        let text = branding.sidebarTextColor(over: appearance)
        return BrandColor(red: text.red, green: text.green, blue: text.blue, alpha: text.alpha * emphasis)
    }
}
