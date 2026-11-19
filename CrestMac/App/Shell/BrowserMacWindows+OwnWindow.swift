import AppKit

/// A tab or a link in a window of its own, and the way back.
extension BrowserMacWindows {
    // MARK: - Actions - Window on a tab

    /// Whether window `sourceWindowID` gives a tab or a link a window of its
    /// own: a browser window does, a normal one and one already on its own. A
    /// private window keeps what it opens to itself.
    func opensWindows(from sourceWindowID: UUID) -> Bool {
        application.windowCoordinator.existingModel(for: sourceWindowID).map { !$0.browser.isPrivateBrowsing } ?? false
    }

    /// Opens tab `tabID` of Space `spaceID` in a window of its own: a copy of
    /// it, with its page and history, moves to a temporary window, as a tab
    /// dragged out of the window does, and the tab stays where it is in
    /// window `sourceWindowID`, unloaded, so closing the new window loses
    /// nothing. Return to Main Window puts the copy in the tab's place.
    /// Answers whether the copy may leave, which the core decides.
    @discardableResult
    func openWindow(showing tabID: UUID, in spaceID: UUID, from sourceWindowID: UUID) -> Bool {
        let coordinator = application.windowCoordinator
        guard opensWindows(from: sourceWindowID), let source = coordinator.existingModel(for: sourceWindowID),
            let space = source.browser.spaceModel(spaceID), space.shownTab(tabID) != nil,
            let copyID = source.browser.duplicateTab(tabID, in: spaceID)
        else { return false }
        guard
            let request = coordinator.prepareTearOff(
                BrowserTabDragItem(tabID: copyID, spaceID: spaceID, profileID: space.profileID),
                from: sourceWindowID, replacing: tabID)
        else {
            _ = source.browser.deleteTab(copyID, in: spaceID)
            return false
        }
        open(request, activation: .key)
        return true
    }

    /// Opens `url` in a window of its own over Space `spaceID` of window
    /// `sourceWindowID`, the kind of window a tab dragged out of the window
    /// gets: it browses with the Space's profile and keeps its tab to itself.
    @discardableResult
    func openWindow(opening url: URL, in spaceID: UUID, from sourceWindowID: UUID) -> Bool {
        let coordinator = application.windowCoordinator
        guard opensWindows(from: sourceWindowID),
            let space = coordinator.existingModel(for: sourceWindowID)?.browser.spaceModel(spaceID),
            !application.spaceAccess.isLocked(space)
        else { return false }
        let request = BrowserMacWindowRequest.temporary(
            sourceWindowID: sourceWindowID, assignment: BrowserSpaceRuntimeAssignment(space: space))
        open(request, activation: .key)
        return coordinator.existingModel(for: request.id)?.browser.openNewTab(url: url) != nil
    }

    // MARK: - Actions - Returning to the main window

    /// Moves every tab of the temporary window `id` back into the Space it
    /// borrowed, in the normal window it was opened from, or else another
    /// normal window, opening one when none is open.
    func returnTabsToMainWindow(from id: UUID) {
        let coordinator = application.windowCoordinator
        guard let source = coordinator.existingModel(for: id), source.isTemporary else { return }
        if let destination = coordinator.normalWindow(preferring: source.request.sourceWindowID) {
            coordinator.returnTabs(from: id, to: destination.id)
            return
        }
        // A normal window opened now takes the tabs once its native window is
        // attached, as a torn-off window takes its tab.
        let request = BrowserMacWindowRequest.normal(sourceWindowID: nil)
        coordinator.prepareReturn(from: id, to: request.id)
        open(request, activation: .key)
    }
}
