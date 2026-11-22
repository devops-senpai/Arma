import SwiftUI

/// A tab menu's Move Card: the card rides the pointer with no keys held, and
/// a click puts it down where the gap stands.
extension BrowserSplitPageSurface {
    // MARK: - Actions - Placing

    /// Picks up `tabID`'s card as a Shift-Command press would, from wherever
    /// the pointer is, `point`, in the card-frame space whose origin in the
    /// window is `surfaceOrigin`. Refused, as a press is, while a sidebar drag
    /// or the command palette owns the pointer, or for a card not on show.
    func placeLift(_ tabID: UUID, at point: CGPoint, surfaceOrigin: CGPoint) -> Bool {
        guard isSelectedSpace, members.count > 1, !model.splitCardLift.isCarrying,
            !model.sidebarInteraction.sidebarReorderState.isDragging, !model.chrome.isCommandPalettePresented,
            let index = members.firstIndex(where: { $0.id == tabID }),
            let frame = memberCardFrames[tabID], !frame.isEmpty
        else { return false }
        let token = model.splitCardLift.reserve()
        loadSnapshot(for: members[index], token: token)
        // A pointer outside the card, over the sidebar the menu opened from,
        // holds the card by its middle rather than by an edge.
        let grip = frame.contains(point) ? point : CGPoint(x: frame.midX, y: frame.midY)
        guard
            model.splitCardLift.begin(
                token: token, tabID: tabID, originIndex: index, cardFrame: frame, pointer: grip,
                surfaceOrigin: surfaceOrigin, placed: true)
        else {
            model.splitCardLift.discard(token)
            return false
        }
        model.splitCardLift.update(pointer: point, gapIndex: index, surfaceOrigin: surfaceOrigin)
        model.focusSplitCard(tabID)
        return true
    }
}
