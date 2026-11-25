import AppKit
import SwiftUI

/// Hands a browser window the capsule of a notice that offers an action, so
/// the window takes presses on it before any view under it can.
///
/// A notice draws over the page, often in the strip under the window's title
/// bar, where AppKit's hit test and the window server can each give a press
/// to the page or the window behind the capsule instead of the capsule.
/// Measuring the capsule and deciding in the window does not depend on
/// either. The bridge also follows the pointer resting on the capsule, from a
/// tracking area that reports by position whatever lies over it, and holds
/// the window still meanwhile so the window server never drags it from
/// there.
struct BrowserPlatformNoticeWindowBridge: NSViewRepresentable {
    let notices: BrowserNotices
    /// The capsule of a notice that offers an action, in the layer's
    /// coordinates, or nil while none shows.
    let actionFrame: CGRect?

    func makeNSView(context: Context) -> BrowserNoticeWindowTargetView {
        BrowserNoticeWindowTargetView(notices: notices)
    }

    func updateNSView(_ nsView: BrowserNoticeWindowTargetView, context: Context) {
        nsView.notices = notices
        nsView.actionFrame = actionFrame
    }

    static func dismantleNSView(_ nsView: BrowserNoticeWindowTargetView, coordinator: Void) {
        nsView.actionFrame = nil
    }
}

/// The window's view of its notice layer: where the capsule that offers an
/// action stands, and whether the pointer rests on it. It takes no presses
/// itself; `BrowserMacWindowNoticePress` asks it where the capsule is.
@MainActor
final class BrowserNoticeWindowTargetView: NSView {
    // MARK: - Variables

    var notices: BrowserNotices
    /// The capsule of a notice that offers an action, in this view's
    /// coordinates, which are the layer's.
    var actionFrame: CGRect? {
        didSet {
            guard actionFrame != oldValue else { return }
            if actionFrame == nil { pointerLeft() }
            updateTrackingAreas()
        }
    }
    private var trackingArea: NSTrackingArea?
    /// Whether the pointer rests on the capsule, as this view last heard.
    private var isPointerInside = false

    /// The capsule in its window's coordinates, while one offers an action.
    var actionFrameInWindow: NSRect? {
        actionFrame.map { convert($0, to: nil) }
    }

    override var isFlipped: Bool { true }

    // MARK: - Initializers

    init(notices: BrowserNotices) {
        self.notices = notices
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions - Window

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        pointerLeft()
        guard let current = window as? BrowserMacWindow, current.noticeTarget === self else { return }
        current.noticeTarget = nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        (window as? BrowserMacWindow)?.noticeTarget = self
        updateTrackingAreas()
    }

    // MARK: - Actions - Pointer

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        trackingArea = nil
        guard let actionFrame, let window else { return }
        let area = NSTrackingArea(
            rect: actionFrame, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
        // A capsule that appears or moves under a resting pointer hears no
        // entry, so the pointer's place now decides.
        let pointer = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        actionFrame.contains(pointer) ? pointerEntered() : pointerLeft()
    }

    override func mouseEntered(with event: NSEvent) {
        pointerEntered()
    }

    override func mouseExited(with event: NSEvent) {
        pointerLeft()
    }

    private func pointerEntered() {
        guard !isPointerInside else { return }
        isPointerInside = true
        notices.hoverChanged(true)
        if let window { BrowserWindowTitleBarGuard.guarding(window).claim(by: self) }
    }

    private func pointerLeft() {
        guard isPointerInside else { return }
        isPointerInside = false
        notices.hoverChanged(false)
        if let window { BrowserWindowTitleBarGuard.guarding(window).release(by: self) }
    }
}
