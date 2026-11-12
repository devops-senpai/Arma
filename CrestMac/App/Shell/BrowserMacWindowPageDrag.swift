import AppKit

/// What the page under a press near the top of a window answers for the
/// window's drag: its view, and whether the spot pressed leaves the press to
/// the window, as a spot with nothing a person can click or type in does.
@MainActor
protocol BrowserMacWindowPageDragTarget: AnyObject {
    var nativeView: NSView { get }
    /// Whether the page leaves a press at `point`, in its view's top-left
    /// coordinates, to the window: false over anything that takes a click,
    /// and false when the page cannot answer in time.
    func leavesPressToWindow(at point: CGPoint) async -> Bool
}

/// Moves a browser window by its pages, as a title bar would, from a press in
/// the top band of the window where the page has nothing to click.
///
/// A plain left press in the band over a page is held while the page says
/// whether the spot takes clicks; a page's engine may run in another process,
/// so it cannot answer at once. Over something that takes the press, or with
/// no answer in time, the window delivers the press and whatever followed it
/// to the page untouched. Over nothing, a drag past a few points hands the
/// press to the window server (`NSWindow.performDrag(with:)`), which moves the
/// window as its title bar would, tiling at the screen's edges included, and
/// a press released without moving still reaches the page, so a click there
/// acts as before.
@MainActor
final class BrowserMacWindowPageDrag {
    // MARK: - Types

    private enum Phase {
        case idle
        /// A press held for the page's answer, with every event since, where
        /// the pointer was on screen at the press, and whether the page left
        /// it to the window once it answered.
        case held(token: Int, events: [NSEvent], pressedAt: NSPoint, leftToWindow: Bool?)
        /// The window server drags the window. What the app still receives of
        /// the press is dropped, so the page never sees a drag or a release
        /// without its press.
        case dragging
    }

    // MARK: - Static Variables

    /// How far below the window's top edge a press may land to move it.
    static let bandHeight: CGFloat = 120
    /// How far the pointer moves before a held press becomes a drag.
    static let dragThreshold: CGFloat = 3

    // MARK: - Variables

    private var phase = Phase.idle
    private var nextToken = 0
    /// Where the pointer is on screen now.
    private let pointer: @MainActor () -> NSPoint

    // MARK: - Initializers

    init(pointer: @escaping @MainActor () -> NSPoint = { NSEvent.mouseLocation }) {
        self.pointer = pointer
    }

    // MARK: - Actions - Events

    /// Takes `event` from `window` when it belongs to a press this holds or
    /// drags, answering whether it did; the window sends on what it did not.
    func take(_ event: NSEvent, in window: BrowserMacWindow) -> Bool {
        switch (event.type, phase) {
        case (.leftMouseDown, .idle):
            return hold(event, in: window)
        case (.leftMouseDown, .held):
            deliverHeld(in: window)
            return false
        case (.leftMouseDown, .dragging):
            // The window server may keep a drag's release to itself, so a new
            // press is how the app learns the drag ended.
            phase = .idle
            return hold(event, in: window)
        case (.leftMouseDragged, .held(let token, var events, let pressedAt, let leftToWindow)):
            events.append(event)
            if leftToWindow == true, hasMoved(from: pressedAt) {
                beginDrag(events, in: window)
            } else {
                phase = .held(token: token, events: events, pressedAt: pressedAt, leftToWindow: leftToWindow)
            }
            return true
        case (.leftMouseUp, .held(let token, var events, let pressedAt, let leftToWindow)):
            events.append(event)
            phase = .held(token: token, events: events, pressedAt: pressedAt, leftToWindow: leftToWindow)
            if leftToWindow != nil { deliverHeld(in: window) }
            return true
        case (.leftMouseDragged, .dragging):
            return true
        case (.leftMouseUp, .dragging):
            phase = .idle
            return true
        default:
            return false
        }
    }

    private func hold(_ event: NSEvent, in window: BrowserMacWindow) -> Bool {
        guard event.window === window,
            !window.styleMask.contains(.fullScreen),
            event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty,
            window.frame.height - event.locationInWindow.y <= Self.bandHeight,
            let page = window.pointerNavigation?.pageDragTarget(at: event)
        else { return false }
        let viewPoint = page.nativeView.convert(event.locationInWindow, from: nil)
        let point = CGPoint(
            x: viewPoint.x,
            y: page.nativeView.isFlipped ? viewPoint.y : page.nativeView.bounds.height - viewPoint.y)
        nextToken += 1
        let token = nextToken
        phase = .held(token: token, events: [event], pressedAt: pointer(), leftToWindow: nil)
        Task { [weak self, weak window, weak page] in
            let leaves = await page?.leavesPressToWindow(at: point) ?? false
            guard let self, let window else { return }
            self.answer(token, leftToWindow: leaves, in: window)
        }
        return true
    }

    /// Acts on the page's answer for the press `token`, if that press is
    /// still held.
    private func answer(_ token: Int, leftToWindow: Bool, in window: BrowserMacWindow) {
        guard case .held(token, let events, let pressedAt, nil) = phase else { return }
        let released = events.contains { $0.type == .leftMouseUp }
        if !leftToWindow || released {
            deliverHeld(in: window)
        } else if hasMoved(from: pressedAt) {
            beginDrag(events, in: window)
        } else {
            phase = .held(token: token, events: events, pressedAt: pressedAt, leftToWindow: true)
        }
    }

    // MARK: - Actions - Moving

    /// Hands the held press, the first of `events`, to the window server to
    /// drag the window by. It takes the drag from where the pointer is now,
    /// so the window catches up with the travel since the press.
    private func beginDrag(_ events: [NSEvent], in window: BrowserMacWindow) {
        guard let press = events.first else { return }
        phase = .dragging
        window.performDrag(with: press)
    }

    private func hasMoved(from pressedAt: NSPoint) -> Bool {
        let now = pointer()
        return hypot(now.x - pressedAt.x, now.y - pressedAt.y) > Self.dragThreshold
    }

    /// Gives the page the held press and everything since, as if it had
    /// never been held.
    private func deliverHeld(in window: BrowserMacWindow) {
        guard case .held(_, let events, _, _) = phase else { return }
        phase = .idle
        for event in events { window.deliver(event) }
    }
}
