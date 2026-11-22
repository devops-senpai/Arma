import CoreGraphics
import Foundation

/// Where a dragged tab, or a carried card, lands among the cards on show: on
/// one side of a card, outside the whole split on one of its sides, where it
/// takes the full height or width, or, for a carried card, onto the middle of
/// another, whose place in the member order it takes.
///
/// Resolved from the pointer and the cards' frames alone, the way
/// `BrowserSplitColumnLayout.insertionIndex` resolves a column, so a drop can be
/// exercised without a live drag. A landing resolves to what the core takes:
/// a member index in Paul's sense, the slot among the other members, and the
/// `SplitShape` the cards tile in once the card is there.
enum BrowserSplitDropLanding: Equatable {
    /// Beside the card at this index among the measured frames.
    case beside(Int, SplitSide)
    case outside(SplitSide)
    /// Onto the middle of the card at this index, for a card of the split.
    case onto(Int)

    // MARK: - Static Variables

    /// How far inside the cards' outer edge a pointer still lands outside the
    /// whole split rather than beside the card under it.
    static let outerBand: CGFloat = 36

    /// The share of a card, from each edge, that still lands beside it. The
    /// middle that is left takes a carried card onto it.
    static let swapInset: CGFloat = 0.3

    // MARK: - Actions - Aiming

    /// The member index and shape a tab dropped at `point` gives the split
    /// whose cards stand at `cardFrames`, a lone card included. The cards'
    /// order and shape are read from the frames themselves, which is how they
    /// tile on screen. Nil with no cards to measure.
    static func joining(at point: CGPoint, cardFrames: [CGRect]) -> (memberIndex: Int, shape: SplitShape)? {
        let frames = cardFrames.filter { !$0.isEmpty }
        guard !frames.isEmpty else { return nil }
        let tiling = tiling(of: frames)
        let ordered = tiling.order.map { frames[$0] }
        guard let landing = aimed(at: point, cardFrames: ordered, landsOnto: false) else { return nil }
        return landing.landed(in: tiling.shape)
    }

    /// The member index and shape a card of the split, at `lifted` among
    /// `cardFrames`, the members' frames in member order, makes when it is put
    /// down at `point` in a split tiled in `shape`. Onto another card, it
    /// swaps with it: `onto` is that card's member index, which the carried
    /// card takes, and the shape stays.
    static func moving(
        _ lifted: Int, at point: CGPoint, cardFrames: [CGRect], shape: SplitShape, rightToLeft: Bool
    ) -> (memberIndex: Int, shape: SplitShape, onto: Int?)? {
        guard cardFrames.indices.contains(lifted), let others = shape.removing(lifted) else { return nil }
        var frames = cardFrames
        frames.remove(at: lifted)
        let measured = rightToLeft ? frames.map(mirrored) : frames
        let aim = rightToLeft ? CGPoint(x: -point.x, y: point.y) : point
        guard let landing = aimed(at: aim, cardFrames: measured, landsOnto: true) else { return nil }
        if case .onto(let index) = landing {
            let other = index < lifted ? index : index + 1
            return (other, shape, other)
        }
        let landed = landing.landed(in: others)
        return (landed.memberIndex, landed.shape, nil)
    }

    /// The card a split member lifted from the sidebar, `member`, swaps with
    /// when it is dropped at `point` onto the middle of another of the cards
    /// at `cardFrames`, by tab; nil anywhere else, where it lands beside a
    /// card as any tab does.
    static func swapping(_ member: UUID, at point: CGPoint, cardFrames: [UUID: CGRect]) -> UUID? {
        let others = cardFrames.filter { $0.key != member && !$0.value.isEmpty }
        guard cardFrames[member] != nil, !others.isEmpty else { return nil }
        let ids = Array(others.keys)
        guard case .onto(let index) = aimed(at: point, cardFrames: ids.map { others[$0]! }, landsOnto: true) else {
            return nil
        }
        return ids[index]
    }

    /// The landing the pointer aims at among `cardFrames`, in reading order:
    /// outside the split within `outerBand` of its edge; onto the card the
    /// pointer is in the middle of, when `landsOnto`; else on the nearest side
    /// of the card under the pointer, or of the nearest card.
    static func aimed(at point: CGPoint, cardFrames: [CGRect], landsOnto: Bool) -> BrowserSplitDropLanding? {
        guard !cardFrames.isEmpty else { return nil }
        let bounds = cardFrames.reduce(CGRect.null) { $0.union($1) }
        if cardFrames.count > 1 || landsOnto, let outside = outerSide(of: point, in: bounds) {
            return .outside(outside)
        }
        let distances = cardFrames.map { distance(from: point, to: $0) }
        let nearest = distances.indices.min { distances[$0] < distances[$1] }!
        let frame = cardFrames[nearest]
        if landsOnto, frame.insetBy(dx: frame.width * swapInset, dy: frame.height * swapInset).contains(point) {
            return .onto(nearest)
        }
        return .beside(nearest, nearestSide(of: point, in: frame))
    }

    /// Where a card landing here sits in `shape`, the shape of the measured
    /// cards: its member index, and the shape it makes.
    func landed(in shape: SplitShape) -> (memberIndex: Int, shape: SplitShape) {
        switch self {
        case .beside(let index, let side):
            (side.isAfter ? index + 1 : index, shape.inserting(at: index, side: side))
        case .outside(let side):
            (side.isAfter ? shape.leafCount : 0, shape.insertingOutside(side))
        case .onto(let index):
            (index, shape)
        }
    }

    // MARK: - Actions - Reading

    /// The shape the cards at `frames` tile in, and their indices in reading
    /// order: cut across wherever no card straddles the cut, columns first.
    /// Cards caught between two layouts, which no cut separates, read as the
    /// row of columns the split view lays out.
    static func tiling(of frames: [CGRect]) -> (shape: SplitShape, order: [Int]) {
        func runs(_ cards: [Int], along axis: SplitAxis) -> [[Int]] {
            let span: (CGRect) -> (CGFloat, CGFloat) = { axis.isHorizontal ? ($0.minX, $0.maxX) : ($0.minY, $0.maxY) }
            var runs: [[Int]] = []
            var end = -CGFloat.infinity
            for card in cards.sorted(by: { span(frames[$0]).0 < span(frames[$1]).0 }) {
                let (start, finish) = span(frames[card])
                if runs.isEmpty || start >= end - 0.5 {
                    runs.append([card])
                    end = finish
                } else {
                    runs[runs.count - 1].append(card)
                    end = max(end, finish)
                }
            }
            return runs
        }
        func tile(_ cards: [Int]) -> (shape: SplitShape, order: [Int]) {
            guard cards.count > 1 else { return (.leaf, cards) }
            for axis in [SplitAxis.horizontal, .vertical] {
                let parts = runs(cards, along: axis)
                guard parts.count > 1 else { continue }
                let tiled = parts.map(tile)
                return (SplitShape.along(axis, tiled.map(\.shape)).normalized, tiled.flatMap(\.order))
            }
            let columns = cards.sorted { frames[$0].minX < frames[$1].minX }
            return (.columns(columns.count), columns)
        }
        return tile(Array(frames.indices))
    }

    /// The side of `bounds` the point is within `outerBand` of, nearest
    /// first, or nil for a point well inside or well outside them.
    private static func outerSide(of point: CGPoint, in bounds: CGRect) -> SplitSide? {
        guard bounds.insetBy(dx: -outerBand, dy: -outerBand).contains(point) else { return nil }
        let distances: [(SplitSide, CGFloat)] = [
            (.leading, point.x - bounds.minX), (.trailing, bounds.maxX - point.x),
            (.above, point.y - bounds.minY), (.below, bounds.maxY - point.y),
        ]
        guard let nearest = distances.min(by: { $0.1 < $1.1 }), nearest.1 <= outerBand else { return nil }
        return nearest.0
    }

    /// The side of `frame` the point is nearest, measured as a share of the
    /// frame on each axis, so a wide card is not all left and right.
    private static func nearestSide(of point: CGPoint, in frame: CGRect) -> SplitSide {
        let width = max(frame.width, 1)
        let height = max(frame.height, 1)
        let distances: [(SplitSide, CGFloat)] = [
            (.leading, (point.x - frame.minX) / width), (.trailing, (frame.maxX - point.x) / width),
            (.above, (point.y - frame.minY) / height), (.below, (frame.maxY - point.y) / height),
        ]
        return distances.min { $0.1 < $1.1 }!.0
    }

    private static func distance(from point: CGPoint, to frame: CGRect) -> CGFloat {
        let dx = max(frame.minX - point.x, 0, point.x - frame.maxX)
        let dy = max(frame.minY - point.y, 0, point.y - frame.maxY)
        return dx * dx + dy * dy
    }

    /// A frame measured on screen, turned so leading is left: right to left,
    /// the first card stands on the right.
    private static func mirrored(_ frame: CGRect) -> CGRect {
        CGRect(x: -frame.maxX, y: frame.minY, width: frame.width, height: frame.height)
    }
}
