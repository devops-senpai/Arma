import SwiftUI

/// The folder's symbol, in the same column the rows below give their favicons.
struct BrowserFolderIcon: View {
    let folder: FolderStateModel
    let isExpanded: Bool
    let metrics: BrowserFolderHeaderMetrics
    /// The look and the Space whose folder colors a folder without its own
    /// wears; without a look the folder draws its own colors alone.
    var branding: SpaceBranding? = nil
    var space: SpaceModel? = nil
    private var iconOnly: Bool { BrowserDeviceAppearanceStore.shared.foldersIconOnly }

    var body: some View {
        BrowserFolderArtwork(symbol: folder.displaySymbol, color: dressedColor, isExpanded: isExpanded)
            .modifier(
                BrowserFolderIconColumn(
                    metrics: metrics,
                    isExpanded: isExpanded
                        && !(iconOnly && BrowserFolderArtwork.customGlyph(for: folder.displaySymbol) != nil)
                )
            )
            .accessibilityHidden(true)
            .environment(\.browserFolderFaceDress, faceDress)
    }
}

/// Applies the saved folder artwork preference to the shared drawing.
struct BrowserFolderArtwork: View {
    let symbol: String
    let color: BrandColor
    var isExpanded = false
    private var iconOnly: Bool { BrowserDeviceAppearanceStore.shared.foldersIconOnly }
    private var tintsTitle: Bool { BrowserDeviceAppearanceStore.shared.foldersTintTitle }

    var body: some View {
        BrowserFolderArtworkContent(
            symbol: symbol, color: color, isExpanded: isExpanded, iconOnly: iconOnly, tintsTitle: tintsTitle)
    }

    static func customGlyph(for symbol: String) -> Text? {
        BrowserFolderArtworkContent.customGlyph(for: symbol)
    }
}

/// Holds the symbol in its column, which is the tab rows' favicon box, so
/// the folder's icon and title line up with the favicons and titles beside
/// it, and sizes it where the shell reads the row from further away than a
/// desk. Without a size of its own the symbol takes the sidebar's text size,
/// at which the folder symbol is as wide as the column; at a larger size it
/// hangs past the column's leading edge, which at the top level is the
/// sidebar's own edge, where the scroll view clips it.
private struct BrowserFolderIconColumn: ViewModifier {
    let metrics: BrowserFolderHeaderMetrics
    let isExpanded: Bool
    private var iconScale: Double { BrowserDeviceAppearanceStore.shared.tabScale }

    func body(content: Content) -> some View {
        content
            .font(
                .system(
                    size: (metrics.iconGlyphSize ?? BrowserSidebarDensity.bodySize(touch: false))
                        * BrowserSidebarDensity(iconScale).contentScale,
                    weight: metrics.iconGlyphWeight)
            )
            // The bottom hinge lowers its optical center.
            .offset(y: (isExpanded ? -1.5 : -0.5) * BrowserSidebarDensity(iconScale).contentScale)
            .frame(
                width: metrics.iconWidth
                    * (metrics.scalesIconColumn ? BrowserSidebarDensity(iconScale).contentScale : 1))
    }
}
