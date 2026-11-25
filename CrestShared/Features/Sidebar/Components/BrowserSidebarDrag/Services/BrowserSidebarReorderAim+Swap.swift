import CoreGraphics
import Foundation

// MARK: - Types

/// Two cards of a split a drop swaps: the member lifted from the sidebar, and
/// the card it was dropped onto the middle of.
struct BrowserSplitCardSwap: Equatable, Sendable {
    let lifted: UUID
    let other: UUID
}

/// A split member dragged from its sidebar row onto the middle of another
/// card of its split: the two swap places, and nothing else moves.
extension BrowserSidebarReorderAim {
    // MARK: - Actions - Swapping

    /// The swap a lift aimed at the content area for `assignment` makes over
    /// `cards`, the cards it measures: only for one tab, lifted alone, whose
    /// own card is among them, over the middle of another. Nil anywhere else,
    /// where it lands beside a card as any tab does.
    func swappingTarget(
        in assignment: BrowserSpaceRuntimeAssignment, cards: [BrowserSidebarReorderGeometry.SplitCard]
    ) -> BrowserSidebarReorderTarget? {
        guard case .tab(let tabID) = lift.item.id, lift.item.selectionRowIDs.count <= 1 else { return nil }
        let frames = cards.reduce(into: [UUID: CGRect]()) { frames, card in
            if let id = card.tabID { frames[id] = card.frame }
        }
        guard let other = BrowserSplitDropLanding.swapping(tabID, at: pointer, cardFrames: frames) else { return nil }
        let swap = BrowserSplitCardSwap(lifted: tabID, other: other)
        return BrowserSidebarReorderTarget(
            kind: .splitInsert(assignment: assignment, index: 0, shape: nil, swapping: swap))
    }
}
