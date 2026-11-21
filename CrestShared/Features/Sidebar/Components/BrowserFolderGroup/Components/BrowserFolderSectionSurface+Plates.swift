import SwiftUI

/// A folder's padding where its Space's picture lays its rows on plates.
extension BrowserFolderSectionSurface {
    // MARK: - Variables

    /// The padding under the folder's last row. On a picture's backing, an
    /// open folder gives up as much as the next row's plate reaches up, so its
    /// last row sits one row's gap from the next, as every other row does.
    var bottomPadding: CGFloat {
        let padding = BrowserSidebarMetrics.containerBottomPadding
        guard isOpen, let spaceID,
            BrowserSpaceBackdropStore.shared.backdrop(for: spaceID)?.tabBacking.reach.platesRows == true
        else {
            return padding
        }
        // The last row keeps half a row's gap under its plate, so the next
        // row's plate, reaching up, lands one row's gap away.
        let separation = BrowserSidebarDensity.current.rowSeparation(
            hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all)
        return padding - BrowserSidebarMetrics.folderPlateReach - CGFloat(separation) / 2
    }
}
