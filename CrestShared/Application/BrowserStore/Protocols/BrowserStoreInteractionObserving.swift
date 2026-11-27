@MainActor
protocol BrowserStoreInteractionObserving: AnyObject {
    func browserWillResetSession()
    func browserDidMoveTab(from source: BrowserTabRuntimeAssignment, to destination: BrowserSpaceRuntimeAssignment)
    /// A tab opened behind the shown page; `show` brings it forward.
    func browserDidOpenBackgroundTab(show: @escaping @MainActor () -> Void)
}

extension BrowserStoreInteractionObserving {
    /// The desktop shell presents confirmation; other observers keep their native presentation.
    func browserDidOpenBackgroundTab(show: @escaping @MainActor () -> Void) {}
}
