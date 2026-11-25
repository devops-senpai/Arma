import SwiftUI

/// What the split view needs to tile a split in a shape, from the window
/// presenting it.
struct BrowserSplitShaping {
    /// The split on show, whose id names its branches' shares; nil for a lone
    /// card a drag is over.
    let groupID: UUID?
    /// The shape the cards tile in, in the order the row draws them: the
    /// core's, or the one a carry has taken them to.
    let shape: SplitShape?
    /// The shape the cards and a drag's placeholder tile in, the placeholder
    /// at the row's `placeholderIndex`.
    let placeholderShape: SplitShape?
    /// The shares the window keeps under a branch's id.
    let persistedShares: (UUID) -> [Double]?
    /// Keeps a branch's shares for the window; nil where a window keeps none.
    let commitShares: ((UUID, [Double]) -> Void)?
}

extension EnvironmentValues {
    /// How the split on show tiles; nil keeps the row of columns.
    @Entry var browserSplitShaping: BrowserSplitShaping?
}

/// A split in a shape: the same cards, slots and surfaces as the row, laid out
/// by `BrowserSplitShapeLayout`, with a divider in every gap of every branch.
///
/// Each branch's shares are a `BrowserSplitWidthTransaction` of their own, the
/// row's own type, measured along the branch's axis and kept for the window
/// under the branch's id (`SplitShape.branchID`). The outermost branch's id is
/// the split's, so it keeps the shares the row of columns kept.
extension BrowserSplitColumnsView {
    // MARK: - Actions - Shape

    /// The shape the row draws, or nil for columns: the shaping's shape, or
    /// with a drop placeholder open, its placeholder shape, when its leaves
    /// count the cards the row lays out.
    func displayedShape(placeholderIndex: Int?) -> SplitShape? {
        guard let shaping else { return nil }
        let shape = placeholderIndex == nil ? shaping.shape : shaping.placeholderShape
        guard let shape, !shape.isColumns,
            shape.leafCount == members.count + (placeholderIndex == nil ? 0 : 1)
        else { return nil }
        return shape
    }

    func shapeLayout(_ shape: SplitShape, gap: CGFloat, panelWidth: CGFloat?) -> BrowserSplitShapeLayout {
        BrowserSplitShapeLayout(shape: shape, shares: branchShares(of: shape), gap: gap, panelWidth: panelWidth)
    }

    /// The handles in every gap of every branch, placed from the frames the
    /// layout gives the cards in `memberWidth`, the row's width beside any
    /// panel.
    func shapeDividers(
        _ shape: SplitShape, memberWidth: CGFloat, gap: CGFloat, direction: LayoutDirection
    ) -> some View {
        GeometryReader { proxy in
            let frames = BrowserSplitShapeLayout.frames(
                of: shape, in: CGRect(x: 0, y: 0, width: memberWidth, height: proxy.size.height),
                shares: branchShares(of: shape), gap: gap)
            ZStack(alignment: .topLeading) {
                ForEach(frames.dividers) { divider in
                    BrowserSplitCardResizeHandle(
                        dividerIndex: divider.index,
                        axis: divider.axis,
                        resize: { resizeBranch(divider, of: shape, delta: $0) },
                        commit: { commitBranch(divider) },
                        accessibilityTitle: divider.axis.isHorizontal
                            ? "Resize Split View Columns" : "Resize Split View Rows",
                        accessibilityMeasurement: String(
                            localized: "\(Int(divider.leadingSize)) and \(Int(divider.trailingSize)) points")
                    )
                    .frame(width: divider.frame.width, height: divider.frame.height)
                    .offset(x: direction.leadingOffset(divider.frame.minX), y: divider.frame.minY)
                }
            }
        }
    }

    /// Each branch's shares, by path: the drag in flight, else what the
    /// window keeps, else equal.
    private func branchShares(of shape: SplitShape) -> [[Int]: [Double]] {
        shape.branches.reduce(into: [:]) { shares, entry in
            guard let id = branchID(entry.path) else { return }
            let count = entry.branch.children.count
            if let transaction = branchWidthTransactions[id], transaction.fractions.count == count {
                shares[entry.path] = transaction.fractions
            } else {
                shares[entry.path] = BrowserSplitColumnLayout.seedFractions(
                    persisted: shaping?.persistedShares(id), memberCount: count)
            }
        }
    }

    /// Moves one boundary of a branch, unanimated, for the same reason the
    /// row's own dividers are: a drag lands on the geometry it was measured
    /// against.
    private func resizeBranch(_ divider: BrowserSplitShapeLayout.Divider, of shape: SplitShape, delta: CGFloat) {
        guard let id = branchID(divider.path), let shares = branchShares(of: shape)[divider.path] else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            var branch = branchWidthTransactions[id] ?? BrowserSplitWidthTransaction(persistedFractions: shares)
            if branch.fractions.count != shares.count {
                branch = BrowserSplitWidthTransaction(persistedFractions: shares)
            }
            branch.resize(
                dividerIndex: divider.index, delta: delta, containerWidth: divider.extent,
                minimum: divider.axis.isHorizontal
                    ? BrowserSplitLayoutMetrics.minimumCardWidth : BrowserSplitShapeLayout.minimumCardHeight)
            branchWidthTransactions[id] = branch
        }
    }

    private func commitBranch(_ divider: BrowserSplitShapeLayout.Divider) {
        guard let id = branchID(divider.path), var branch = branchWidthTransactions[id] else { return }
        let committed = branch.commit()
        branchWidthTransactions[id] = branch
        if let committed { shaping?.commitShares?(id, committed) }
    }

    private func branchID(_ path: [Int]) -> UUID? {
        shaping?.groupID.map { SplitShape.branchID(groupID: $0, path: path) }
    }
}
