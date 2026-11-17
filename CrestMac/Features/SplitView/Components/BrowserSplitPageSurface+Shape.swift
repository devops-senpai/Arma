import SwiftUI

/// The split surface's part in a split tiled in a shape: what the columns
/// view tiles, and where a carry over it aims.
extension BrowserSplitPageSurface {
    // MARK: - Actions - Shape

    /// How the cards tile: the core's shape, or the one a carry has taken
    /// them to while the card is on the pointer.
    var shaping: BrowserSplitShaping {
        let lift = isSelectedSpace ? model.splitCardLift.lift : nil
        let carried = lift?.isSettling == false ? lift?.gapShape : nil
        return model.browser.splitShaping(
            in: space, shape: carried ?? model.browser.shownSplitShape(in: space),
            placeholderShape: placeholderShape, keepsShares: isSelectedSpace)
    }

    /// Where the card carried at `point` lands, in two dimensions, and the
    /// frames it aimed at. A row of columns aims as `SplitShape.columns`, so a
    /// card carried onto another's top or bottom edge stacks there, while one
    /// that stays in the row answers the same shape and its release commits
    /// Paul's member move alone, storing no shape.
    func shapedLiftAim(
        at point: CGPoint, lifted: UUID, rightToLeft: Bool
    ) -> (memberIndex: Int, shape: SplitShape?, swapsWith: UUID?, frames: [UUID: CGRect])? {
        let shape = model.browser.shownSplitShape(in: space) ?? .columns(members.count)
        let frames = model.splitCardLift.lift?.aimFrames ?? memberCardFrames
        guard
            let gap = BrowserSplitCardLift.shapedGap(
                at: point, members: members.map(\.id), lifted: lifted, shape: shape, cardFrames: frames,
                rightToLeft: rightToLeft)
        else { return nil }
        return (gap.memberIndex, gap.shape, gap.swapsWith, frames)
    }

    /// Whether a press at `point` is over a divider of a split tiled in a
    /// shape, rows included, which the resize keeps; nil over a row of
    /// columns, which Paul's divider check answers.
    func isOverShapeDivider(_ point: CGPoint, frames: [UUID: CGRect]) -> Bool? {
        guard model.browser.shownSplitShape(in: space) != nil else { return nil }
        return BrowserSplitCardLift.isOverTileDivider(point, cardFrames: members.compactMap { frames[$0.id] })
    }
}
