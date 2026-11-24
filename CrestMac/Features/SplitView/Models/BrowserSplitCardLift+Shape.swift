import CoreGraphics
import Foundation

extension BrowserSplitCardLift {
    // MARK: - Actions - Shape

    /// Where a card carried over a split tiled in `shape` would land, in two
    /// dimensions: beside another card on any of its sides, outside the whole
    /// split, or onto the middle of another card, whose member index it takes.
    ///
    /// The member index is the gap's, exactly as the row's `gapIndex(...)`
    /// answers it, and the shape is the one the cards tile in with the gap
    /// where it stands, or nil when that is the split's own: a release then
    /// commits Paul's member move alone. Onto another card's middle,
    /// `swapsWith` names that card, and the release swaps the two instead.
    /// `cardFrames` are the members' as the carry first aimed at them, so the
    /// cards stepping aside for the gap never move the aim.
    static func shapedGap(
        at point: CGPoint,
        members: [UUID],
        lifted: UUID,
        shape: SplitShape,
        cardFrames: [UUID: CGRect],
        rightToLeft: Bool
    ) -> (memberIndex: Int, shape: SplitShape?, swapsWith: UUID?)? {
        guard let origin = members.firstIndex(of: lifted) else { return nil }
        // The carried card's own frame is not asked for, just as Paul's
        // `gapIndex` filters it out: the row draws the gap in another branch
        // of its slot switch, whose new view registers before the card's old
        // one disappears and removes the frame. Requiring it sent the aim to
        // the row's fallback, which re-tiled the cards, and the next aim
        // measured that preview against the split's own shape. `moving`
        // drops the carried card's frame before it measures anything.
        let frames = members.compactMap { $0 == lifted ? .zero : cardFrames[$0] }
        guard frames.count == members.count,
            let landed = BrowserSplitDropLanding.moving(
                origin, at: point, cardFrames: frames, shape: shape, rightToLeft: rightToLeft)
        else { return nil }
        return (landed.memberIndex, landed.shape == shape ? nil : landed.shape, landed.onto.map { members[$0] })
    }

    /// The row as it is drawn while the carried card is over another card's
    /// middle: the two traded places and every other card where it was, as the
    /// release leaves them. Paul's `displayMembers(_:lifted:gapIndex:)` slides
    /// the cards between them instead, which is a move.
    static func displayMembers<Member: Identifiable>(
        _ members: [Member], lifted liftedTabID: UUID, swappingWith otherTabID: UUID
    ) -> [Member] where Member.ID == UUID {
        guard let lifted = members.firstIndex(where: { $0.id == liftedTabID }),
            let other = members.firstIndex(where: { $0.id == otherTabID })
        else { return members }
        var swapped = members
        swapped.swapAt(lifted, other)
        return swapped
    }

    /// Whether `point` belongs to a divider between two cards of a split
    /// tiled in a shape, a row divider as well as a column one, rather than
    /// to the card whose frame contains it.
    ///
    /// Paul's `isOverDivider(_:orderedCardFrames:)` measures the midpoints
    /// between cards ordered left to right, which is every divider of a row
    /// of columns. In a shape two cards stacked one above the other are
    /// neighbours in that order too, and the midpoint between them falls in
    /// the middle of the column. This asks of every two cards that face each
    /// other across a gap no wider than a handle, along either axis, and
    /// only over the run where both cards stand.
    static func isOverTileDivider(
        _ point: CGPoint,
        cardFrames: [CGRect],
        hitWidth: CGFloat = BrowserSplitLayoutMetrics.resizeHandleHitWidth
    ) -> Bool {
        let reach = max(0, hitWidth) / 2
        func faces(_ first: CGRect, _ second: CGRect, along axis: SplitAxis) -> Bool {
            let (end, start) = axis.isHorizontal ? (first.maxX, second.minX) : (first.maxY, second.minY)
            let (across, low, high) =
                axis.isHorizontal
                ? (point.y, max(first.minY, second.minY), min(first.maxY, second.maxY))
                : (point.x, max(first.minX, second.minX), min(first.maxX, second.maxX))
            let along = axis.isHorizontal ? point.x : point.y
            return start >= end - 0.5 && start - end <= hitWidth && across >= low && across <= high
                && abs(along - (end + start) / 2) <= reach
        }
        return cardFrames.contains { first in
            cardFrames.contains { second in
                faces(first, second, along: .horizontal) || faces(first, second, along: .vertical)
            }
        }
    }
}
