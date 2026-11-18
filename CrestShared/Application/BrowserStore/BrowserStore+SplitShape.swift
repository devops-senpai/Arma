import Foundation

/// The shape the split this window shows tiles in, read from the core's read
/// model, and the intent that lays it out.
extension BrowserStore {
    // MARK: - Actions - Reading

    /// The shape the split this window shows in `space` tiles in, or nil for
    /// a row of columns: the core's, while its leaves count the cards on show.
    func shownSplitShape(in space: SpaceModel) -> SplitShape? {
        guard let groupID = shownSplitGroupID(in: space),
            let shape = space.splitGroups.first(where: { $0.id == groupID })?.shape,
            shape.leafCount == cards(in: space).count
        else { return nil }
        return shape
    }

    /// What the split view needs to tile the split this window shows in
    /// `space` in `shape`: the window's shares for each branch, which it
    /// keeps only where `keepsShares`.
    func splitShaping(
        in space: SpaceModel, shape: SplitShape?, placeholderShape: SplitShape?, keepsShares: Bool
    ) -> BrowserSplitShaping {
        BrowserSplitShaping(
            groupID: shownSplitGroupID(in: space),
            shape: shape,
            placeholderShape: placeholderShape,
            persistedShares: { [weak self] in self?.window.splitColumnFractions(for: $0) },
            commitShares: keepsShares ? { [weak self] in self?.resizeSplitColumns($1, for: $0) } : nil
        )
    }

    // MARK: - Actions - Arranging

    /// Lays the split `groupID` out in `shape`, after moving `tabID`, when one
    /// is named, to member `memberIndex`, in the Space this window shows.
    @discardableResult
    func arrangeSplit(
        _ groupID: UUID,
        in shape: SplitShape,
        moving tabID: UUID? = nil,
        to memberIndex: Int? = nil,
        matching assignment: BrowserSpaceRuntimeAssignment
    ) -> Bool {
        guard spaceModel(matching: assignment) != nil, selectedSpaceID == assignment.spaceID else { return false }
        return family.send(
            ArrangeSplit(
                workspaceID: family.workspaceID, spaceID: assignment.spaceID, groupID: groupID, shape: shape,
                tabID: tabID, memberIndex: memberIndex),
            from: self)
    }

    /// Swaps the cards `tabID` and `otherTabID`, two members of one split,
    /// in the Space this window shows: each takes the other's tile.
    @discardableResult
    func swapSplitMembers(
        _ tabID: UUID, with otherTabID: UUID, matching assignment: BrowserSpaceRuntimeAssignment
    ) -> Bool {
        guard spaceModel(matching: assignment) != nil, selectedSpaceID == assignment.spaceID else { return false }
        return family.send(
            SwapSplitMembers(
                workspaceID: family.workspaceID, spaceID: assignment.spaceID, tabID: tabID, otherTabID: otherTabID),
            from: self)
    }
}
