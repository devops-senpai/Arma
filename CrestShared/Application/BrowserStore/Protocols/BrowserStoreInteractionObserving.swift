import Foundation

@MainActor
protocol BrowserStoreInteractionObserving: AnyObject {
    func browserWillResetSession()
    func browserDidMoveTab(from source: BrowserTabRuntimeAssignment, to destination: BrowserSpaceRuntimeAssignment)
    /// A tab opened behind the shown page; `show` brings it forward.
    func browserDidOpenBackgroundTab(show: @escaping @MainActor () -> Void)
    func browserDidOpenBackgroundTab()
    func browserDidOpenTab(_ tabID: UUID, in spaceID: UUID)
}

extension BrowserStoreInteractionObserving {
    /// The desktop shell presents confirmation; other observers keep their native presentation.
    func browserDidOpenBackgroundTab(show: @escaping @MainActor () -> Void) {}
    func browserDidOpenBackgroundTab() {}

    /// The desktop shell brings the tab's row into view; other observers leave their list where it is.
    func browserDidOpenTab(_ tabID: UUID, in spaceID: UUID) {}
}
