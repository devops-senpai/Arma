import SwiftUI

/// Shows the notice a window's `notices` holds at the top of the area the
/// layer covers, for as long as the notice lasts. A newer notice replaces one
/// still showing.
struct BrowserNoticeLayer: View {
    // MARK: - Static Variables

    /// The coordinate space the layer measures its capsule in.
    static let space = "browser-notice-layer"

    // MARK: - Variables

    let notices: BrowserNotices
    /// Where in the area the notice stands: its top trailing corner, or, on a
    /// phone, the middle of its top.
    var alignment = Alignment.topTrailing
    /// How far the notice stands below the top of the area.
    var topInset = BrowserRootMetrics.noticeInset
    /// How far the notice keeps from each side of the area.
    var sideInset = BrowserRootMetrics.noticeInset

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Where the showing capsule stands in the layer, while one shows.
    @State private var capsuleFrame: CGRect?

    var body: some View {
        ZStack {
            if let notice = notices.shown {
                BrowserNoticeView(
                    notice: notice, alignment: alignment, topInset: topInset, sideInset: sideInset,
                    performAction: { notices.performAction() },
                    capsuleFrameChanged: { capsuleFrame = $0 }
                )
                .id(notice)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named(Self.space))
        // The platform takes presses on a capsule that offers an action, and
        // follows the pointer resting on it, ahead of whatever lies under it.
        .background {
            BrowserPlatformNoticeWindowBridge(
                notices: notices, actionFrame: notices.shown?.action == nil ? nil : capsuleFrame)
        }
        .zIndex(BrowserRootMetrics.feedbackZIndex)
        .animation(motion, value: notices.shown)
    }

    // MARK: - Actions - Presentation

    /// A notice arriving presents; the last one leaving dismisses.
    private var motion: Animation? {
        (notices.shown == nil ? CrestMotion.dismissal : CrestMotion.feedbackPresentation)
            .unlessReducingMotion(reduceMotion)
    }
}
