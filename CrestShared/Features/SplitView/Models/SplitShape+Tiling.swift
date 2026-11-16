import Foundation

/// The core's `SplitShape` as the split view reads and previews it.
///
/// The core owns a split's shape and every edit to it. These mirror the few
/// edits a drop or a carry previews — a card landing beside a leaf or outside
/// the whole shape, a card leaving — so the placeholder or the gap already
/// stands where the release puts the card, and they name each branch the way
/// the core keys the shares a window keeps for it.
extension SplitShape {
    // MARK: - Static Variables

    /// One card.
    static let leaf = SplitShape(axis: nil, children: [])

    // MARK: - Variables

    var isLeaf: Bool { axis == nil }

    /// How many cards the shape lays out.
    var leafCount: Int { isLeaf ? 1 : children.reduce(0) { $0 + $1.leafCount } }

    /// Whether the shape is one row of columns, which the core keeps as no
    /// shape at all.
    var isColumns: Bool { axis == .horizontal && children.allSatisfy(\.isLeaf) }

    /// Every branch, the outermost first, with its path of child indices.
    var branches: [(path: [Int], branch: SplitShape)] {
        branches(at: [])
    }

    /// The shape with every branch of one child given way to it, and every
    /// branch inside one that runs the same way merged into it, as the core
    /// keeps a shape.
    var normalized: SplitShape {
        pruned(removing: -1, from: 0).shape ?? .leaf
    }

    // MARK: - Initializers

    static func along(_ axis: SplitAxis, _ children: [SplitShape]) -> SplitShape {
        SplitShape(axis: axis, children: children)
    }

    /// One row of `count` columns.
    static func columns(_ count: Int) -> SplitShape {
        .along(.horizontal, Array(repeating: .leaf, count: count))
    }

    // MARK: - Actions - Editing

    /// The shape with a card landed on `side` of leaf `leaf`: beside it in the
    /// branch that already runs that way, or in a new branch that takes the
    /// leaf's place. The new card reads as leaf `leaf` before the card and
    /// `leaf + 1` after it.
    func inserting(at leaf: Int, side: SplitSide) -> SplitShape {
        guard !isLeaf else { return insertingOutside(side) }
        var first = 0
        var children = children
        for index in children.indices {
            let count = children[index].leafCount
            if leaf >= first, leaf < first + count {
                if children[index].isLeaf, axis == side.axis {
                    children.insert(.leaf, at: side.isAfter ? index + 1 : index)
                } else {
                    children[index] = children[index].inserting(at: leaf - first, side: side)
                }
                return SplitShape(axis: axis, children: children)
            }
            first += count
        }
        return insertingOutside(side)
    }

    /// The shape with a card landed on `side` of the whole of it, the full
    /// height or width of the split.
    func insertingOutside(_ side: SplitSide) -> SplitShape {
        SplitShape.along(side.axis, side.isAfter ? [self, .leaf] : [.leaf, self]).normalized
    }

    /// The shape without leaf `leaf`; nil for one that held no other card.
    func removing(_ leaf: Int) -> SplitShape? {
        pruned(removing: leaf, from: 0).shape
    }

    private func pruned(removing removed: Int, from first: Int) -> (shape: SplitShape?, next: Int) {
        guard let axis else { return (first == removed ? nil : self, first + 1) }
        var kept: [SplitShape] = []
        var next = first
        for child in children {
            let pruned = child.pruned(removing: removed, from: next)
            next = pruned.next
            guard let shape = pruned.shape else { continue }
            if shape.axis == axis { kept += shape.children } else { kept.append(shape) }
        }
        switch kept.count {
        case 0: return (nil, next)
        case 1: return (kept[0], next)
        default: return (.along(axis, kept), next)
        }
    }

    // MARK: - Actions - Branches

    /// The id the window keeps a branch's shares under, as the core derives
    /// it: the split's own for the outermost branch, and for each branch
    /// inside it the split's with its last bytes marked by the branch's path.
    static func branchID(groupID: UUID, path: [Int]) -> UUID {
        var bytes = withUnsafeBytes(of: groupID.uuid) { Array($0) }
        for (depth, index) in path.enumerated() {
            bytes[15 - depth] ^= 0x80 | UInt8(truncatingIfNeeded: index + 1)
        }
        return bytes.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }

    private func branches(at path: [Int]) -> [(path: [Int], branch: SplitShape)] {
        guard !isLeaf else { return [] }
        return [(path, self)] + children.enumerated().flatMap { $1.branches(at: path + [$0]) }
    }
}
