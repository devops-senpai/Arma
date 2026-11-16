import SwiftUI

extension View {
    func browserIconCustomizationPopover(
        _ presentation: BrowserIconCustomizationPresentation,
        arrowEdge: Edge? = .trailing
    ) -> some View {
        modifier(
            BrowserIconCustomizationPopoverModifier(
                presentation: presentation,
                arrowEdge: arrowEdge
            )
        )
    }
}

private struct BrowserIconCustomizationPopoverModifier: ViewModifier {
    let presentation: BrowserIconCustomizationPresentation
    let arrowEdge: Edge?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// The look of the sidebar the picker opens from, which a Space's theme
    /// may make dark while the system is light.
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.crestPopover(isPresented: presentation.isPresented, arrowEdge: preferredArrowEdge) {
            popoverContent
        }
    }

    /// Compact windows let the system choose an edge that fits the picker.
    private var preferredArrowEdge: Edge? {
        horizontalSizeClass == .compact ? nil : arrowEdge
    }

    private var popoverContent: some View {
        BrowserIconCustomizationView(
            title: presentation.title,
            currentEmoji: presentation.currentEmoji,
            currentSystemSymbol: presentation.currentSystemSymbol,
            showsReset: presentation.showsReset,
            resetTitle: presentation.resetTitle,
            setEmoji: presentation.setEmoji,
            setSystemSymbol: presentation.setSystemSymbol,
            reset: presentation.reset
        )
        // The popover inherits the sidebar's theme text color, meant for the
        // sidebar's own background; its symbols and labels take the system's
        // colors instead, on a popover in the sidebar's look, so they read
        // whatever the theme.
        .foregroundStyle(.primary)
        .preferredColorScheme(colorScheme)
        .presentationCompactAdaptation(.popover)
    }
}
