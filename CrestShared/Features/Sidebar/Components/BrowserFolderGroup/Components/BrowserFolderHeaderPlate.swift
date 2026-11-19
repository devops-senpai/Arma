import SwiftUI

/// The Space's tab backing behind a folder's header, in the shape and height
/// a tab row's plate takes: the header is shorter than a tab row by the
/// folder's own padding, so the plate reaches past it to a whole row,
/// centered.
struct BrowserFolderHeaderPlate: ViewModifier {
    let configuration: BrowserFolderGroupConfiguration
    let interaction: BrowserFolderGroupInteractionContext

    // MARK: - Variables

    private var plateReach: CGFloat { BrowserSidebarMetrics.folderPlateReach }

    /// The gap between two rows' plates, half of which the header keeps here.
    private var rowSeparation: CGFloat {
        CGFloat(
            BrowserSidebarDensity.current.rowSeparation(
                hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all))
    }

    /// The height of one tab row at the sidebar's density.
    private var tabRowHeight: CGFloat {
        BrowserSidebarDensity.current.rowHeight(
            base: CrestLayout.sidebarRowHeight, touch: !configuration.headerMetrics.usesFixedRowHeight)
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .background {
                BrowserSidebarTabBackingPlate(
                    cornerRadius: BrowserSidebarMetrics.layerCornerRadius(depth: configuration.depth)
                )
                .frame(height: tabRowHeight)
                .padding(.horizontal, BrowserSidebarMetrics.layerInset)
            }
            // An open folder's first row sits right under the header, past the
            // padding a closed folder keeps there, so the header keeps the room
            // its plate reaches into and the row below stays a row's gap away.
            .padding(.bottom, interaction.isExpanded.wrappedValue ? plateReach + rowSeparation / 2 : 0)
    }
}
