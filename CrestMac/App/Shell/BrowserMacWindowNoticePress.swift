import AppKit

/// Takes presses on the capsule of a notice that offers an action, ahead of
/// every view in the window, as a button would: the press is the notice's
/// whole, and releasing on the capsule takes the action while releasing off
/// it takes nothing. A right press there is the notice's too, so no menu of
/// the page under it opens.
///
/// The notice's layer measures the capsule (`BrowserNoticeWindowTargetView`)
/// so this never depends on which view AppKit's hit test would pick under it.
@MainActor
final class BrowserMacWindowNoticePress {
    // MARK: - Variables

    /// The button of the press on the capsule, until its release.
    private var pressedButton: NSEvent.EventType?

    // MARK: - Actions - Events

    /// Takes `event` from `window` when it belongs to a press on the notice,
    /// answering whether it did; the window sends on what it did not.
    func take(_ event: NSEvent, in window: BrowserMacWindow) -> Bool {
        switch event.type {
        case .leftMouseDown, .rightMouseDown:
            guard event.window === window, let frame = window.noticeTarget?.actionFrameInWindow,
                frame.contains(event.locationInWindow)
            else { return false }
            pressedButton = event.type
            return true
        case .leftMouseDragged, .rightMouseDragged:
            return pressedButton != nil
        case .leftMouseUp:
            guard pressedButton == .leftMouseDown else { return pressedButton != nil && release() }
            pressedButton = nil
            if let target = window.noticeTarget, let frame = target.actionFrameInWindow,
                frame.contains(event.locationInWindow)
            {
                target.notices.performAction()
            }
            return true
        case .rightMouseUp:
            guard pressedButton != nil else { return false }
            return release()
        default:
            return false
        }
    }

    private func release() -> Bool {
        pressedButton = nil
        return true
    }
}
