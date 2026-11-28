import Foundation

/// The cards as a swap in flight shows them: a split member dragged from the
/// sidebar onto another card's middle already stands in that card's place.
extension BrowserPageSurfacePresentation {
    // MARK: - Actions - Swapping

    /// `cards` with the two a swap aimed at this Space trades already traded,
    /// which is the order the drop commits; `cards` as they are otherwise.
    /// The cards keep their identities, so each moves its host rather than
    /// building another.
    static func swapping(
        _ cards: [TabStateModel], resolvedTarget: BrowserSidebarReorderTarget?, spaceID: UUID
    ) -> [TabStateModel] {
        guard let split = resolvedTarget?.kind.splitInsertion, let swap = split.swapping,
            split.assignment.spaceID == spaceID,
            let from = cards.firstIndex(where: { $0.id == swap.lifted }),
            let to = cards.firstIndex(where: { $0.id == swap.other })
        else { return cards }
        var swapped = cards
        swapped.swapAt(from, to)
        return swapped
    }
}
