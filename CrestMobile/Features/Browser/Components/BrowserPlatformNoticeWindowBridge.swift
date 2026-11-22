import SwiftUI

/// iPhone and iPad take a notice's action through its button, as SwiftUI
/// delivers the tap, so the layer's window bridge adds nothing here.
struct BrowserPlatformNoticeWindowBridge: View {
    let notices: BrowserNotices
    let actionFrame: CGRect?

    var body: some View {
        EmptyView()
    }
}
