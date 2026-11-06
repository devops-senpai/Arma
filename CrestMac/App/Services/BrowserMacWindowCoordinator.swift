import AppKit
import Observation

/// Normal windows present the app's workspace. Temporary windows own disposable
/// workspaces and borrow the source Space's website profile.
@Observable
@MainActor
final class BrowserMacWindowCoordinator {
    private struct PendingTransfer {
        let sourceWindowID: UUID
        let item: BrowserTabDragItem
        /// The tab the moving copy stands in for, which stays behind,
        /// unloaded, in the window it was copied from.
        var replacing: UUID?
    }

    /// Where a tab stood in its Space when it left a normal window for a
    /// temporary one: its section, its folder, and the tab that followed it
    /// there.
    private struct TabOrigin {
        let placement: TabPlacement
        let folderID: UUID?
        let followingTabID: UUID?
    }

    let browser: BrowserStore
    private let pages: BrowserPagePool
    let spaceAccess: BrowserSpaceAccessController
    private let windowLayouts: BrowserWindowLayouts
    /// Where every window's utility lists keep the person's choices.
    private let utilityDefaults: UserDefaults?
    @ObservationIgnored private var windows: [UUID: BrowserMacWindowModel] = [:]
    /// Temporary windows that closed or whose transfer was canceled. They are
    /// never restored, so a scene that asks for one again once it went, as
    /// SwiftUI does while it tears a window down, gets nothing instead of a
    /// new workspace.
    @ObservationIgnored private var retiredTemporaryWindows: Set<UUID> = []
    @ObservationIgnored private var pendingTransfers: [UUID: PendingTransfer] = [:]
    @ObservationIgnored private var transferExpirations: [UUID: Task<Void, Never>] = [:]
    /// Where each tab now in a temporary window stood before it left a
    /// normal one, so Return to Main Window can put it back there.
    @ObservationIgnored private var tabOrigins: [UUID: TabOrigin] = [:]
    /// The tab each copy in a temporary window stands in for: the tab stayed
    /// behind, unloaded, and the copy takes its place when it returns.
    @ObservationIgnored private var replacements: [UUID: UUID] = [:]

    init(
        browser: BrowserStore, pages: BrowserPagePool, spaceAccess: BrowserSpaceAccessController,
        windowLayouts: BrowserWindowLayouts, utilityDefaults: UserDefaults?
    ) {
        self.browser = browser
        self.pages = pages
        self.spaceAccess = spaceAccess
        self.windowLayouts = windowLayouts
        self.utilityDefaults = utilityDefaults
    }

    func existingModel(for id: UUID) -> BrowserMacWindowModel? { windows[id] }

    /// The normal window a temporary window's tabs return to: `preferredID`'s
    /// when that window is open and normal, else the normal window nearest
    /// the front, if any is open.
    func normalWindow(preferring preferredID: UUID?) -> BrowserMacWindowModel? {
        if let preferred = preferredID.flatMap({ windows[$0] }), !preferred.isTemporary { return preferred }
        let normal = windows.values.filter { !$0.isTemporary }
        let front = NSApp.orderedWindows.lazy.compactMap { window in normal.first { $0.window === window } }.first
        return front ?? normal.first
    }

    /// The page pool of each open window.
    var openWindowPages: [BrowserPagePool] { windows.values.map(\.pages) }

    @discardableResult
    func activateExistingWindow(for source: BrowserStore) -> Bool {
        guard let space = source.shownSpace, !spaceAccess.isLocked(space) else { return false }
        let assignment = BrowserSpaceRuntimeAssignment(space: space)
        let candidates = windows.values.filter {
            !$0.isTemporary && $0.window != nil && $0.browser.family === source.family
                && $0.browser.spaceModel(matching: assignment) != nil
        }
        let destination =
            candidates.first { $0.browser === source }
            ?? candidates.first { $0.browser.shownSpace?.id == space.id }
            ?? candidates.first
        guard let destination, let window = destination.window else { return false }
        destination.browser.selectSpace(space.id)
        if let tab = source.shownTab {
            destination.browser.selectTab(tab.id)
        }
        destination.pages.select()
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        return true
    }

    func preparePresentation(_ window: NSWindow, for id: UUID) {
        guard let model = windows[id] else { return }
        model.window = window
        model.tearOffPlacement?.prepare(window)
    }

    func didMeasureRow(_ row: BrowserSidebarReorderRow, in id: UUID) {
        guard let model = windows[id], let placement = model.tearOffPlacement, placement.isPending,
            let tabID = row.id.tabID, model.browser.spaceModel(matching: row.space)?.shownTab(tabID) != nil
        else { return }
        placement.place(at: row)
    }

    func model(for request: BrowserMacWindowRequest) -> BrowserMacWindowModel? {
        guard !retiredTemporaryWindows.contains(request.id) else { return nil }
        if let existing = windows[request.id] { return existing }
        let source = request.sourceWindowID.flatMap { windows[$0]?.browser } ?? browser
        let windowBrowser: BrowserStore
        let state: BrowserWindowStateStore
        if request.kind == .temporary {
            guard let assignment = request.sourceAssignment,
                let temporary = browser.makeTemporaryWindowStore(in: assignment, id: request.id)
            else { return nil }
            windowBrowser = temporary
            state = BrowserWindowStateStore(
                id: request.id, browser: temporary, layouts: BrowserWindowLayouts(defaults: nil))
        } else {
            // A window without a record of its own starts as the window it was
            // opened from shows.
            windowBrowser = browser.makeWindowStore(
                BrowserWindowOpening(id: request.id, saved: true, copying: source.windowID))
            state = BrowserWindowStateStore(id: request.id, browser: windowBrowser, layouts: windowLayouts)
        }
        let transient = BrowserTransientBrowsingCoordinator()
        let windowPages = pages.makeWindowPool(
            browser: windowBrowser, sharesRuntimes: request.kind == .normal,
            transientBrowsing: transient, spaceAccess: spaceAccess)
        let model = BrowserMacWindowModel(
            request: request, browser: windowBrowser, pages: windowPages,
            transientBrowsing: transient, windowState: state, utilityDefaults: utilityDefaults)
        windows[request.id] = model
        return model
    }

    @discardableResult
    func attach(_ window: NSWindow, to id: UUID) -> Bool {
        guard let model = windows[id] else {
            window.close()
            return false
        }
        model.window = window
        model.tearOffPlacement?.attach(window) { [weak model] in
            model?.pages.setWindowFocused(true)
        }
        model.pages.bindNativeWindow(window)
        _ = completePendingTransfer(to: id)
        return windows[id] === model
    }

    func closeWindow(_ id: UUID) {
        guard let model = windows.removeValue(forKey: id) else { return }
        model.tearOffPlacement?.cancel()
        cancelPendingTransfer(to: id)
        for destination in pendingTransfers.keys.filter({ pendingTransfers[$0]?.sourceWindowID == id }) {
            cancelPendingTransfer(to: destination)
        }
        if model.isTemporary {
            // Its tabs go with it, and so does where they came from.
            for tab in model.browser.shownSpace?.tabs.models ?? [] {
                tabOrigins[tab.id] = nil
                replacements[tab.id] = nil
            }
            model.pages.closeWindowWorkspace()
            model.windowState.removePersistedState()
            model.browser.family.temporarySettingsBrowser?.close()
        } else {
            model.pages.releaseWindowPresentation()
        }
        model.browser.close()
        // A temporary window's workspace is its own and goes with it.
        if model.isTemporary {
            retiredTemporaryWindows.insert(id)
            model.browser.family.close()
        }
    }

    /// Closes each temporary window whose workspace the core closed, because
    /// the Space it borrowed was deleted, took another profile or lost its
    /// owner.
    func reconcileTemporaryWorkspaces() {
        let invalid = windows.values.filter {
            $0.isTemporary && !$0.browser.family.isOpen
        }
        for model in invalid {
            model.pages.closeWindowWorkspace()
            model.window?.close()
            closeWindow(model.id)
        }
    }

    /// Preparing a destination is reversible. The shared workspace changes only
    /// after the new scene has a native window and has accepted the transfer.
    func prepareTearOff(
        _ item: BrowserTabDragItem, from sourceID: UUID,
        at point: CGPoint? = nil, grabFraction: CGPoint = CGPoint(x: 0.5, y: 0.5), replacing original: UUID? = nil
    ) -> BrowserMacWindowRequest? {
        guard let source = windows[sourceID], canTearOff(item, from: source) else { return nil }
        let request = BrowserMacWindowRequest.temporary(
            sourceWindowID: sourceID, assignment: item.spaceAssignment)
        guard let destination = model(for: request) else { return nil }
        if let point {
            destination.tearOffPlacement = BrowserMacTabTearOffPlacement(
                assignment: item.runtimeAssignment, dropPoint: point, grabFraction: grabFraction)
        }
        pendingTransfers[request.id] = PendingTransfer(sourceWindowID: sourceID, item: item, replacing: original)
        transferExpirations[request.id] = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            self?.cancelPendingTransfer(to: request.id)
        }
        return request
    }

    @discardableResult
    func completePendingTransfer(to destinationID: UUID) -> Bool {
        guard let pending = pendingTransfers[destinationID],
            let source = windows[pending.sourceWindowID], let destination = windows[destinationID],
            transfer(pending.item, from: source, to: destination)
        else {
            if pendingTransfers[destinationID] != nil { cancelPendingTransfer(to: destinationID) }
            return false
        }
        pendingTransfers.removeValue(forKey: destinationID)
        transferExpirations.removeValue(forKey: destinationID)?.cancel()
        if let original = pending.replacing {
            replacements[pending.item.tabID] = original
            unloadTab(original, in: pending.item.spaceAssignment, of: source)
        }
        return true
    }

    /// Unloads tab `id`, which a copy left the window for, so only the copy
    /// runs. A window that still shows it shows the Start Page instead.
    private func unloadTab(
        _ id: UUID, in assignment: BrowserSpaceRuntimeAssignment, of model: BrowserMacWindowModel
    ) {
        guard let tab = model.browser.spaceModel(matching: assignment)?.shownTab(id) else { return }
        if model.browser.selectedTabID(in: assignment.spaceID) == id {
            _ = model.browser.presentStartPageForSpaceEntry()
        }
        let runtime = BrowserTabRuntimeAssignment(
            tabID: id, spaceID: assignment.spaceID, profileID: assignment.profileID)
        if tab.placement.isDurable {
            _ = BrowserDurableTabCloseAction(browser: model.browser, spaceAccess: spaceAccess).perform(runtime)
        } else {
            _ = model.pages.unloadPage(for: id, matching: assignment)
        }
        model.pages.select()
    }

    func cancelPendingTransfer(to id: UUID) {
        transferExpirations.removeValue(forKey: id)?.cancel()
        guard pendingTransfers.removeValue(forKey: id) != nil else { return }
        retiredTemporaryWindows.insert(id)
        guard let destination = windows.removeValue(forKey: id) else { return }
        destination.tearOffPlacement?.cancel()
        destination.pages.closeWindowWorkspace()
        destination.browser.family.temporarySettingsBrowser?.close()
        destination.browser.close()
        destination.browser.family.close()
        destination.window?.close()
    }

    @discardableResult
    func move(_ item: BrowserTabDragItem, from sourceID: UUID, to destinationID: UUID) -> Bool {
        guard sourceID != destinationID, let source = windows[sourceID], let destination = windows[destinationID]
        else { return false }
        return transfer(item, from: source, to: destination)
    }

    /// Moves the tab from temporary window `sourceID` back to normal window
    /// `destinationID`, and puts it where it stood before it left: in its
    /// section and folder, ahead of the tab that followed it while that tab
    /// is still there. A tab whose folder is gone, or that came from the open
    /// tabs, stays an open tab.
    @discardableResult
    func returnTab(_ item: BrowserTabDragItem, from sourceID: UUID, to destinationID: UUID) -> Bool {
        let origin = tabOrigins[item.tabID]
        let original = replacements.removeValue(forKey: item.tabID)
        guard move(item, from: sourceID, to: destinationID) else { return false }
        // A copy takes the place of the tab it stands in for, which goes.
        if let original, let destination = windows[destinationID],
            let space = destination.browser.spaceModel(matching: item.spaceAssignment),
            let stayed = space.shownTab(original)
        {
            _ = destination.browser.moveSessionTab(
                item.tabID, in: space.id, to: stayed.placement, folderID: stayed.folderID, before: original)
            _ = destination.browser.deleteTab(original, matching: item.spaceAssignment)
            return true
        }
        guard let origin, let destination = windows[destinationID],
            let space = destination.browser.spaceModel(matching: item.spaceAssignment),
            origin.placement != .current || origin.folderID != nil,
            origin.folderID.map({ space.folders.model($0) != nil }) ?? true
        else { return true }
        let following = origin.followingTabID.flatMap { space.shownTab($0) }.flatMap { tab in
            tab.placement == origin.placement && tab.folderID == origin.folderID ? tab.id : nil
        }
        _ = destination.browser.moveSessionTab(
            item.tabID, in: space.id, to: origin.placement, folderID: origin.folderID, before: following)
        return true
    }

    func windowID(at screenPoint: CGPoint, excluding sourceID: UUID) -> UUID? {
        guard
            let window = NSApp.orderedWindows.first(where: {
                $0.isVisible && !$0.ignoresMouseEvents && $0.frame.contains(screenPoint)
            })
        else {
            return nil
        }
        return windows.values.first(where: { $0.window === window && $0.id != sourceID })?.id
    }

    func isInsideAnyWindow(screenPoint: CGPoint) -> Bool {
        NSApp.orderedWindows.contains { $0.isVisible && !$0.ignoresMouseEvents && $0.frame.contains(screenPoint) }
    }

    func isInsideWindow(_ id: UUID, screenPoint: CGPoint) -> Bool {
        windows[id]?.window?.frame.contains(screenPoint) == true
    }

    /// The core decides whether the dragged tab may leave its window: the
    /// window still shows the Space with its profile and it is unlocked, holds
    /// the tab, and the drag carries that tab alone. A Space this window is
    /// deleting never lets a tab go.
    private func canTearOff(_ item: BrowserTabDragItem, from model: BrowserMacWindowModel) -> Bool {
        guard model.browser.spaceModel(matching: item.spaceAssignment) != nil else { return false }
        let question = CanTearOff(
            windowID: model.browser.windowID, spaceID: item.spaceID, profileID: item.profileID,
            tabID: item.tabID, draggedTabs: item.selection?.ids)
        return (try? model.browser.core.query(question))?.allowed == true
    }

    /// Where the tab stands in its Space in the window this coordinator's
    /// workspace shows, before it leaves.
    private func origin(of item: BrowserTabDragItem) -> TabOrigin? {
        guard let space = browser.spaceModel(matching: item.spaceAssignment), let tab = space.shownTab(item.tabID)
        else { return nil }
        let section = space.tabs.models.filter { $0.placement == tab.placement && $0.folderID == tab.folderID }
        let index = section.firstIndex { $0.id == tab.id }
        let following = index.flatMap { section.indices.contains($0 + 1) ? section[$0 + 1].id : nil }
        return TabOrigin(placement: tab.placement, folderID: tab.folderID, followingTabID: following)
    }

    /// Moves the tab and its live page to `destination`'s window.
    private func transfer(
        _ item: BrowserTabDragItem, from source: BrowserMacWindowModel, to destination: BrowserMacWindowModel
    ) -> Bool {
        guard canTearOff(item, from: source),
            let targetSpace = destination.browser.spaceModel(matching: item.spaceAssignment),
            !spaceAccess.isLocked(targetSpace),
            source.browser.canTransferTab(
                item.tabID, matching: item.spaceAssignment,
                to: destination.browser, in: item.spaceAssignment)
        else { return false }
        let images = source.browser.core.state.favicons
        guard
            let tab = source.browser.spaceModel(matching: item.spaceAssignment)?.shownTab(item.tabID)
                .map({ BrowserPageTab($0, images: images) }),
            destination.pages.canTransferTabRuntime(
                from: source.pages, matching: item.runtimeAssignment, in: targetSpace)
        else { return false }
        let origin = source.isTemporary ? nil : origin(of: item)
        guard
            source.browser.transferTab(
                item.tabID, matching: item.spaceAssignment, to: destination.browser, in: item.spaceAssignment)
        else { return false }
        // A tab remembers where it stood only while it is in a temporary
        // window; in a normal one it stands where the person put it.
        tabOrigins[item.tabID] = destination.isTemporary ? origin ?? tabOrigins[item.tabID] : nil
        // Both moves have been validated above. There is no actor suspension
        // between committing the workspace graphs and relocating the runtime.
        let movedTab =
            destination.browser.spaceModel(matching: item.spaceAssignment)?.shownTab(tab.id)
            .map { BrowserPageTab($0, images: destination.browser.core.state.favicons) } ?? tab
        let transferred = destination.pages.transferTabRuntime(
            from: source.pages, matching: item.runtimeAssignment, as: movedTab, in: targetSpace)
        assert(transferred)
        source.pages.reconcile()
        source.pages.select()
        destination.pages.reconcile()
        destination.pages.select()
        if destination.tearOffPlacement?.isPending != true {
            destination.pages.setWindowFocused(true)
            destination.window?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
