import Foundation

// MARK: - Types

/// One request, from a menu, that the content area pick a Split View card up
/// and carry it on the pointer until a click puts it down: the move a
/// Shift-Command drag makes, for a hand that is not holding keys.
struct BrowserSplitCardCarryRequest: Equatable, Sendable {
    let tabID: UUID
    /// Advances with every request, so the same card asked for again is a new
    /// request.
    let sequence: Int
}

/// A tab menu's Move Card, handed from the sidebar to the content area that
/// shows the card.
extension BrowserSidebarInteractionState {
    // MARK: - Actions - Carrying

    /// Asks the content area to pick `tabID`'s card up and carry it with the
    /// pointer until a click puts it down.
    func requestCardCarry(_ tabID: UUID) {
        cardCarryRequest = BrowserSplitCardCarryRequest(
            tabID: tabID, sequence: (cardCarryRequest?.sequence ?? 0) &+ 1)
    }

    /// Takes up `request` once: true the first time any content area asks,
    /// false for a request already taken up.
    func claimCardCarry(_ request: BrowserSplitCardCarryRequest) -> Bool {
        guard request.sequence > claimedCardCarrySequence else { return false }
        claimedCardCarrySequence = request.sequence
        return true
    }
}
