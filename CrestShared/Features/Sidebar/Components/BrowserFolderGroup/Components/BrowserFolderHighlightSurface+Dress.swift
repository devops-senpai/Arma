import SwiftUI

/// A folder highlight in a Space's theme: the theme's own fill opacity, in
/// place of the one the folder color intensity gives.
extension BrowserFolderHighlightSurface {
    // MARK: - Actions - Opacity

    /// The fill's opacity the theme names, held to 0…1 and raised as the
    /// intensity's baseline is when transparency is reduced, or nil when the
    /// intensity decides.
    func dressedFillOpacity(reducingTransparency: Bool) -> Double? {
        guard let highlightOpacity else { return nil }
        let opacity = highlightOpacity.isFinite ? min(max(highlightOpacity, 0), 1) : 1
        return reducingTransparency ? max(opacity, 0.28) : opacity
    }
}
