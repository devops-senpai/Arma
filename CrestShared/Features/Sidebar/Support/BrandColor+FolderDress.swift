import Foundation

extension BrandColor {
    // MARK: - Static Variables

    /// The opacity of the black shade a folder's artwork lays over its back
    /// face when the Space names no back color.
    static let folderBackShadeOpacity = 0.22

    // MARK: - Variables

    /// This color shaded as a folder's back face is when that face follows
    /// the front.
    var folderBackShade: BrandColor {
        BrandColor(red: 0, green: 0, blue: 0).composited(opacity: Self.folderBackShadeOpacity, over: self)
    }
}
