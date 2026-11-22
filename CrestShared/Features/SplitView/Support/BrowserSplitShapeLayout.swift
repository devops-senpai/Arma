import SwiftUI

/// Tiles a split's cards in its shape: the layout `BrowserSplitColumnsView`
/// swaps in for its row of columns while the split keeps a shape.
///
/// Each branch spreads its extent along its axis among its children with
/// `BrowserSplitColumnLayout.widths`, the same arithmetic one row of columns
/// uses, so a branch across is a row of columns and a branch down is the same
/// row turned on its side. The subviews are the row's own slots in the row's
/// own order — the members, the drop placeholder where it stands, and the
/// extension panel last — and leaf `n` of the shape is slot `n`. The frames
/// are pure, so the dividers are placed from exactly the frames the cards are.
struct BrowserSplitShapeLayout: Layout {
    // MARK: - Types

    /// One boundary between two children of a branch: where its handle sits,
    /// and what a drag on it is measured against.
    struct Divider: Identifiable {
        /// The branch's path of child indices from the outermost branch.
        let path: [Int]
        /// The gap after the child at this index.
        let index: Int
        let axis: SplitAxis
        /// The handle's frame: the gap and its overhang, across the branch.
        let frame: CGRect
        /// The branch's extent along its axis, which a drag's travel is a
        /// share of.
        let extent: CGFloat
        /// The sizes of the children on either side, which the divider reads
        /// out to assistive technologies.
        let leadingSize: CGFloat
        let trailingSize: CGFloat

        var id: [Int] { path + [index] }
    }

    /// Every frame a shape lays out.
    struct Frames {
        /// One frame per leaf, in leaf order.
        var leaves: [CGRect] = []
        var dividers: [Divider] = []
    }

    // MARK: - Static Variables

    /// The shortest a card becomes in a stack, lower than the narrowest it
    /// becomes in a row: a page still reads at less height than width.
    static let minimumCardHeight: CGFloat = 160

    // MARK: - Variables

    let shape: SplitShape
    /// Each branch's shares, by its path; a branch whose shares do not count
    /// its children shares equally.
    let shares: [[Int]: [Double]]
    let gap: CGFloat
    /// The width the trailing panel takes beside the shape, or nil for none.
    let panelWidth: CGFloat?

    // MARK: - Actions - Layout

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var area = bounds
        if let panelWidth, let panel = subviews.last {
            area.size.width = max(0, bounds.width - panelWidth - gap)
            panel.place(
                at: CGPoint(x: bounds.maxX - panelWidth, y: bounds.minY),
                proposal: ProposedViewSize(width: panelWidth, height: bounds.height))
        }
        let leaves = Self.frames(of: shape, in: area, shares: shares, gap: gap).leaves
        for (subview, frame) in zip(subviews, leaves) {
            subview.place(at: frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// The frames `shape` lays out in `container`.
    static func frames(
        of shape: SplitShape,
        in container: CGRect,
        shares: [[Int]: [Double]],
        gap: CGFloat = BrowserSplitLayoutMetrics.interCardGap,
        handleWidth: CGFloat = BrowserSplitLayoutMetrics.resizeHandleHitWidth,
        minimumSize: CGSize = CGSize(width: BrowserSplitLayoutMetrics.minimumCardWidth, height: minimumCardHeight)
    ) -> Frames {
        var frames = Frames()
        place(
            shape, at: [], in: container, shares: shares, gap: gap, handleWidth: handleWidth, minimumSize: minimumSize,
            into: &frames)
        return frames
    }

    private static func place(
        _ shape: SplitShape, at path: [Int], in container: CGRect, shares: [[Int]: [Double]], gap: CGFloat,
        handleWidth: CGFloat, minimumSize: CGSize, into frames: inout Frames
    ) {
        guard let axis = shape.axis else {
            frames.leaves.append(container)
            return
        }
        let extent = axis.isHorizontal ? container.width : container.height
        let fractions = BrowserSplitColumnLayout.seedFractions(
            persisted: shares[path], memberCount: shape.children.count)
        let sizes = BrowserSplitColumnLayout.widths(
            containerWidth: extent,
            fractions: fractions,
            gap: gap,
            minimum: axis.isHorizontal ? minimumSize.width : minimumSize.height)
        var offset: CGFloat = 0
        for (index, child) in shape.children.enumerated() {
            let size = sizes.indices.contains(index) ? sizes[index] : 0
            let frame =
                axis.isHorizontal
                ? CGRect(x: container.minX + offset, y: container.minY, width: size, height: container.height)
                : CGRect(x: container.minX, y: container.minY + offset, width: container.width, height: size)
            place(
                child, at: path + [index], in: frame, shares: shares, gap: gap, handleWidth: handleWidth,
                minimumSize: minimumSize, into: &frames)
            offset += size
            guard index + 1 < shape.children.count else { continue }
            let center = offset + gap / 2 - handleWidth / 2
            frames.dividers.append(
                Divider(
                    path: path, index: index, axis: axis,
                    frame: axis.isHorizontal
                        ? CGRect(
                            x: container.minX + center, y: container.minY, width: handleWidth,
                            height: container.height)
                        : CGRect(
                            x: container.minX, y: container.minY + center, width: container.width,
                            height: handleWidth),
                    extent: extent, leadingSize: size,
                    trailingSize: sizes.indices.contains(index + 1) ? sizes[index + 1] : 0))
            offset += gap
        }
    }
}
