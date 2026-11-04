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
/// to the page untouched. Over nothing, a drag past a few points moves the
/// window from its own drag events, as `BrowserWindowTitleBarSurfaceView`
/// does, and a press released without moving still reaches the page, so a
/// click there acts as before.
@MainActor
final class BrowserMacWindowPageDrag {
    // MARK: - Types

    private enum Phase {
        case idle
        /// A press held for the page's answer, with every event since, and
        /// whether the page left it to the window once it answered.
        case held(token: Int, events: [NSEvent], start: Start, leftToWindow: Bool?)
        case dragging(Start)
    }

    /// Where the window and the pointer, in screen points, were at the press.
    private struct Start {
        let windowOrigin: NSPoint
        let pointer: NSPoint
    }

    // MARK: - Static Variables

    /// How far below the window's top edge a press may land to move it.
    static let bandHeight: CGFloat = 120
    /// How far the pointer moves before a held press becomes a drag.
    static let dragThreshold: CGFloat = 3

    // MARK: - Variables

    private var phase = Phase.idle
    private var nextToken = 0
    /// Where the pointer is on screen now. Each move reads it live, as the
    /// title bar surface does: a drag event's own location is relative to
    /// the window as it stood, which the drag keeps moving.
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
        case (.leftMouseDragged, .held(let token, var events, let start, let leftToWindow)):
            events.append(event)
            if leftToWindow == true, hasMoved(from: start) {
                beginDrag(start, in: window)
            } else {
                phase = .held(token: token, events: events, start: start, leftToWindow: leftToWindow)
            }
            return true
        case (.leftMouseUp, .held(let token, var events, let start, let leftToWindow)):
            events.append(event)
            phase = .held(token: token, events: events, start: start, leftToWindow: leftToWindow)
            if leftToWindow != nil { deliverHeld(in: window) }
            return true
        case (.leftMouseDragged, .dragging(let start)):
            move(window, from: start)
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
        phase = .held(
            token: token, events: [event],
            start: Start(windowOrigin: window.frame.origin, pointer: pointer()), leftToWindow: nil)
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
        guard case .held(token, let events, let start, nil) = phase else { return }
        let released = events.contains { $0.type == .leftMouseUp }
        if !leftToWindow || released {
            deliverHeld(in: window)
        } else if hasMoved(from: start) {
            beginDrag(start, in: window)
        } else {
            phase = .held(token: token, events: events, start: start, leftToWindow: true)
        }
    }

    // MARK: - Actions - Moving

    private func beginDrag(_ start: Start, in window: BrowserMacWindow) {
        phase = .dragging(start)
        move(window, from: start)
    }

    private func move(_ window: NSWindow, from start: Start) {
        let now = pointer()
        window.setFrameOrigin(
            NSPoint(
                x: start.windowOrigin.x + now.x - start.pointer.x,
                y: start.windowOrigin.y + now.y - start.pointer.y))
    }

    private func hasMoved(from start: Start) -> Bool {
        let now = pointer()
        return hypot(now.x - start.pointer.x, now.y - start.pointer.y) > Self.dragThreshold
    }

    /// Gives the page the held press and everything since, as if it had
    /// never been held.
    private func deliverHeld(in window: BrowserMacWindow) {
        guard case .held(_, let events, _, _) = phase else { return }
        phase = .idle
        for event in events { window.deliver(event) }
    }
}
