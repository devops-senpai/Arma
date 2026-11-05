import SwiftUI

/// Gives a window's page pool the way to open the Quick Window that shows a
/// window one of its pages asked for, such as a sign-in popup, and the
/// browser window the person opens a link in.
struct BrowserPopupWindowPresentation: ViewModifier {
    let pages: BrowserPagePool

    @Environment(\.browserMacWindows) private var windows

    func body(content: Content) -> some View {
        content.onAppear {
            pages.popupWindowPresenter = { [windows] request in windows?.openQuickWindow(request) }
            let windowID = pages.windowID
            guard let windows, windows.opensWindows(from: windowID) else { return }
            pages.linkWindowPresenter = { [windows] url, spaceID in
                windows.openWindow(opening: url, in: spaceID, from: windowID)
            }
        }
    }
}
