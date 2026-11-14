import SwiftUI

/// One hover boundary for a folder's header and all of its visible contents,
/// held the container padding in from every edge of the folder's surface. A
/// Split View wears it too, with no folder of its own to be dropped into.
struct BrowserFolderSectionSurface: ViewModifier {
    let color: BrandColor
    var highlightColor: BrandColor? = nil
    var highlightOpacity: Double = 1
    var textColorMode: SpaceTextColorMode = .automatic
    /// How many folders hold this one.
    var depth = 0
    var isSelected = false
    /// Whether the folder shows its contents.
    var isOpen = false
    /// The Space the folder belongs to, whose backdrop says whether its rows
    /// lie on plates.
    var spaceID: UUID?
    /// The folder a drop can file into, or nil for a container that takes
    /// none, such as a Split View.
    let folderID: UUID?
    let reorder: BrowserSidebarReorderState
    /// Whether the surface steps itself in from the sidebar's edges, as a
    /// folder's does; a Split View's row already stands in place.
    var insetsSurface = true
    private var isTargeted: Bool { folderID.map(reorder.isTargetedFolder) ?? false }

    @Environment(\.folderPreviewShowsHighlight) private var previewShowsHighlight
    @State private var backdrops = BrowserSpaceBackdropStore.shared
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var alwaysVisible: Bool { BrowserDeviceAppearanceStore.shared.foldersAlwaysVisible }
    private var showsBorders: Bool { BrowserDeviceAppearanceStore.shared.foldersShowBorders }

    /// The padding under the folder's last row. On a picture's backing, an
    /// open folder gives up as much as the next row's plate reaches up, so its
    /// last row sits one row's gap from the next, as every other row does.
    private var bottomPadding: CGFloat {
        let padding = BrowserSidebarMetrics.containerBottomPadding
        guard isOpen, let spaceID, backdrops.backdrop(for: spaceID)?.tabBacking.reach.platesRows == true else {
            return padding
        }
        // The last row keeps half a row's gap under its plate, so the next
        // row's plate, reaching up, lands one row's gap away.
        let separation = BrowserSidebarDensity.current.rowSeparation(
            hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all)
        return padding - BrowserSidebarMetrics.folderPlateReach - CGFloat(separation) / 2
    }

    func body(content: Content) -> some View {
        content
            .padding(.top, BrowserSidebarMetrics.containerPadding)
            .padding(.bottom, bottomPadding)
            .contentShape(.rect)
            .modifier(
                BrowserFolderHighlightSurface(
                    color: color, highlightColor: highlightColor, highlightOpacity: highlightOpacity,
                    textColorMode: textColorMode,
                    showsFill: alwaysVisible || previewShowsHighlight || isHovered || isSelected || isTargeted,
                    showsBorders: showsBorders, depth: depth, insetsSurface: insetsSurface,
                    isSelected: isSelected,
                    emphasisOpacity: alwaysVisible && (isHovered || isTargeted) ? (isTargeted ? 0.16 : 0.08) : 0)
            )
            .onHover { isHovered = $0 }
            .animation(
                CrestMotion.surface.unlessReducingMotion(reduceMotion),
                value: isHovered || isTargeted || isSelected
            )
    }
}
