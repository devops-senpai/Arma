import SwiftUI

/// The colors a folder's icon wears in its Space's look.
extension BrowserFolderIcon {
    // MARK: - Variables

    /// The front face's color: the one the Space gives the folder, or the
    /// folder's own without a Space look.
    var dressedColor: BrandColor {
        guard let branding else { return folder.displayColor }
        guard let space else { return branding.folderColor ?? folder.displayColor }
        return branding.folderColor(of: folder, in: space)
    }

    /// The back face and outline colors the Space gives the folder, if any.
    var faceDress: BrowserFolderFaceDress {
        guard let branding, let space else { return BrowserFolderFaceDress() }
        return BrowserFolderFaceDress(
            backColor: branding.folderBackColor(of: folder, in: space),
            outlineColor: branding.folderOutlineColor(of: folder, in: space))
    }
}
