import CoreGraphics

extension BrowserSidebarMetrics {
    // MARK: - Variables

    /// How far a folder's tab backing reaches past its header, above and
    /// below: the header is a tab row's height less the folder's padding, and
    /// its plate is a whole tab row, centered, so half that padding, less the
    /// separation the header keeps itself.
    @MainActor
    static var folderPlateReach: CGFloat {
        let padding = containerPadding + containerBottomPadding + containerSpacing * 2
        let separation = BrowserSidebarDensity.current.rowSeparation(
            hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all)
        return max(0, (padding - CGFloat(separation)) / 2)
    }
}
