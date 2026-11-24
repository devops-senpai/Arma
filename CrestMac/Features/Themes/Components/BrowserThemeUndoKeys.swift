import AppKit
import SwiftUI

/// Undo and Redo on the Themes page: Command-Z takes back the last run of
/// edits to a theme and Command-Shift-Z makes it again, while a text field
/// being typed in keeps both keys for its own text. The keys are caught
/// before the menu sends them down the responder chain, where a page in the
/// window could take them instead.
struct BrowserThemeUndoKeys: NSViewRepresentable {
    // MARK: - Variables

    /// Takes back the last edit, answering whether there was one.
    let undo: () -> Bool
    /// Makes the last undone edit again, answering whether there was one.
    let redo: () -> Bool

    // MARK: - Actions - Presentation

    func makeNSView(context: Context) -> ObserverView { ObserverView() }

    func updateNSView(_ view: ObserverView, context: Context) {
        view.undo = undo
        view.redo = redo
    }

    static func dismantleNSView(_ view: ObserverView, coordinator: ()) { view.stop() }

    // MARK: - Types

    final class ObserverView: NSView {
        // MARK: - Variables

        var undo: () -> Bool = { false }
        var redo: () -> Bool = { false }
        private var monitor: Any?

        // MARK: - Actions - Events

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, event.window === self.window, !(self.window?.firstResponder is NSText),
                    event.charactersIgnoringModifiers?.lowercased() == "z"
                else { return event }
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    .subtracting([.capsLock, .numericPad, .function])
                switch modifiers {
                case [.command]: return self.undo() ? nil : event
                case [.command, .shift]: return self.redo() ? nil : event
                default: return event
                }
            }
        }

        // MARK: - Mutators

        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }
}
