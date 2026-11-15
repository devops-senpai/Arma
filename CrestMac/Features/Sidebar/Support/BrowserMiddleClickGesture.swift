import AppKit
import SwiftUI

@available(macOS 26.0, *)
struct BrowserMiddleClickGesture: NSGestureRecognizerRepresentable {
    let perform: @MainActor () -> Void

    func makeNSGestureRecognizer(context: Context) -> NSClickGestureRecognizer {
        let recognizer = NSClickGestureRecognizer()
        recognizer.buttonMask = 1 << 2
        recognizer.numberOfClicksRequired = 1
        return recognizer
    }

    func handleNSGestureRecognizerAction(
        _ recognizer: NSClickGestureRecognizer,
        context: Context
    ) {
        guard recognizer.state == .ended else { return }
        perform()
    }
}

extension View {
    @ViewBuilder
    func browserOnMiddleClick(
        perform: @escaping @MainActor () -> Void
    ) -> some View {
        if #available(macOS 26.0, *) {
            gesture(BrowserMiddleClickGesture(perform: perform))
        } else {
            overlay { BrowserMiddleClickView(perform: perform) }
        }
    }
}

/// SwiftUI takes an AppKit gesture recognizer only from macOS 26. Before it,
/// the same recognizer sits on a view laid over the content, which AppKit
/// finds for the middle button alone, so every other event reaches the content.
private struct BrowserMiddleClickView: NSViewRepresentable {
    // MARK: - Types

    final class Target: NSView {
        var perform: @MainActor () -> Void = {}

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent,
                [.otherMouseDown, .otherMouseDragged, .otherMouseUp].contains(event.type)
            else { return nil }
            return super.hitTest(point)
        }

        @objc func clicked(_ recognizer: NSClickGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            perform()
        }
    }

    // MARK: - Variables

    let perform: @MainActor () -> Void

    // MARK: - Actions - View

    func makeNSView(context: Context) -> Target {
        let view = Target()
        let recognizer = NSClickGestureRecognizer(target: view, action: #selector(Target.clicked))
        recognizer.buttonMask = 1 << 2
        recognizer.numberOfClicksRequired = 1
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateNSView(_ view: Target, context: Context) {
        view.perform = perform
    }
}
