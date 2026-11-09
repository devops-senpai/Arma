import Foundation

extension BrowserSidebarInteractionState {
    // MARK: - Actions - Link Feedback

    /// Confirms a link or palette row that opened behind the page the person
    /// is using, offering to show the tab it opened.
    func browserDidOpenBackgroundTab(show: @escaping @MainActor () -> Void) {
        BrowserNoticeCenter.shared.post(.openedInBackgroundTab(show: show))
    }
}
