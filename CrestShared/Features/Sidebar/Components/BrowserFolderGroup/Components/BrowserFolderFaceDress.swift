import SwiftUI

extension EnvironmentValues {
    /// The colors a Space's theme gives the folder artwork drawn here.
    @Entry var browserFolderFaceDress = BrowserFolderFaceDress()
}

/// The colors a Space's theme gives a folder's faces beyond its own color:
/// the back face, which otherwise shades the front, and a line around each
/// face, which a folder otherwise goes without.
struct BrowserFolderFaceDress: Equatable {
    // MARK: - Static Variables

    /// The outline's width, as a share of the folder's width.
    private static let outlineWidthShare = 0.085

    // MARK: - Variables

    /// The back face's own color, or nil to shade the front's for it.
    var backColor: BrandColor?
    /// The line drawn around each face, or nil for none.
    var outlineColor: BrandColor?

    // MARK: - Actions - Drawing

    /// Fills the back face's `path` in its own color, or `color` shaded, and
    /// outlines it.
    func drawBack(_ path: Path, color: BrandColor, in context: GraphicsContext, width: CGFloat) {
        context.fill(path, with: .color((backColor ?? color.folderBackShade).color))
        if let outlineColor {
            context.stroke(
                path, with: .color(outlineColor.color),
                style: StrokeStyle(lineWidth: width * Self.outlineWidthShare, lineJoin: .round))
        }
    }

    /// Outlines the front face, a rounded rectangle of `size` with corners of
    /// `radius`, inside its edge.
    func drawFrontOutline(in context: GraphicsContext, size: CGSize, radius: CGFloat) {
        guard let outlineColor else { return }
        let inset = size.width * Self.outlineWidthShare / 2
        let outline = Path(
            roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset),
            cornerRadius: max(0, radius - inset))
        context.stroke(
            outline, with: .color(outlineColor.color),
            style: StrokeStyle(lineWidth: size.width * Self.outlineWidthShare, lineJoin: .round))
    }
}
