import SwiftUI

/// The picture of a split's shape for a menu row: a small card for each leaf,
/// laid out by `BrowserSplitShapeLayout` the way the split lays its pages out.
/// Drawn as a template image, so the menu tints it like the symbols beside it.
enum BrowserSplitArrangementIcon {
    // MARK: - Static Variables

    private static let size = CGSize(width: 18, height: 13)
    private static let gap: CGFloat = 1.5
    private static let cornerRadius: CGFloat = 1.5

    // MARK: - Actions - Drawing

    static func image(for shape: SplitShape) -> Image {
        let frames = BrowserSplitShapeLayout.frames(
            of: shape, in: CGRect(origin: .zero, size: size), shares: [:], gap: gap, handleWidth: 0,
            minimumSize: .zero
        ).leaves
        return Image(size: size) { context in
            for frame in frames {
                context.fill(Path(roundedRect: frame, cornerRadius: cornerRadius), with: .color(.black))
            }
        }
        .renderingMode(.template)
    }
}
