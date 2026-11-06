import SwiftUI

/// One hover boundary for a folder's header and all of its visible contents,
/// held the container padding in from every edge of the folder's surface.
struct BrowserFolderSectionSurface: ViewModifier {
    let color: BrandColor
    var intensity: Double = 0
    var textColorMode: SpaceTextColorMode = .automatic
    /// How many folders hold this one.
    var depth = 0
    var isSelected = false
    /// Whether the folder shows its contents.
    var isOpen = false
    /// The Space the folder belongs to, whose backdrop says whether its rows
    /// lie on plates.
    var spaceID: UUID?
    let folderID: UUID
    let reorder: BrowserSidebarReorderState
    private var isTargeted: Bool { reorder.isTargetedFolder(folderID) }

    @Environment(\.folderPreviewShowsHighlight) private var previewShowsHighlight
    @State private var backdrops = BrowserSpaceBackdropStore.shared
    private var tabScale: Double { BrowserDeviceAppearanceStore.shared.tabScale }
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var alwaysVisible: Bool { BrowserDeviceAppearanceStore.shared.foldersAlwaysVisible }
    private var showsBorders: Bool { BrowserDeviceAppearanceStore.shared.foldersShowBorders }

    /// The padding under the folder's last row. On a picture's backing, an
    /// open folder gives up as much as the next row's plate reaches up, so its
    /// last row sits one row's gap from the next, as every other row does.
    private var bottomPadding: CGFloat {
        let padding = BrowserSidebarMetrics.containerBottomPadding(tabScale: tabScale)
        guard isOpen, let spaceID, backdrops.backdrop(for: spaceID)?.tabBacking.reach.platesRows == true else {
            return padding
        }
        // The last row keeps half a row's gap under its plate, so the next
        // row's plate, reaching up, lands one row's gap away.
        let separation = BrowserSidebarDensity(tabScale).rowSeparation(
            hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all)
        return padding - BrowserSidebarMetrics.folderPlateReach(tabScale: tabScale) - CGFloat(separation) / 2
    }

    func body(content: Content) -> some View {
        content
            .padding(.top, BrowserSidebarMetrics.containerPadding)
            .padding(.bottom, bottomPadding)
            .contentShape(.rect)
            .modifier(
                BrowserFolderHighlightSurface(
                    color: color, intensity: intensity,
                    textColorMode: textColorMode,
                    showsFill: alwaysVisible || previewShowsHighlight || isHovered || isSelected || isTargeted,
                    showsBorders: showsBorders, depth: depth,
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
