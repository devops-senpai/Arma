import AppKit

/// A page answers for the window's drag by asking its own document what is
/// under the press, in the agent world the page never sees, so it works the
/// same on every engine.
extension BrowserPage: BrowserMacWindowPageDragTarget {
    // MARK: - Static Variables

    /// How long the window holds a press for the page's answer before giving
    /// the press to the page.
    static let windowDragAnswerLimit: Duration = .milliseconds(150)

    /// What takes a press without a cursor saying so: links, controls,
    /// fields, embedded content and anything that declares a role or focus.
    private static let pressTakers = [
        "a[href]", "button", "input", "select", "textarea", "label", "summary", "option", "iframe", "video",
        "audio", "canvas", "embed", "object", "img[usemap]", "[contenteditable]:not([contenteditable=\"false\"])",
        "[draggable=\"true\"]", "[onclick]", "[tabindex]:not([tabindex=\"-1\"])", "[role=\"button\"]",
        "[role=\"link\"]", "[role=\"tab\"]", "[role=\"menuitem\"]", "[role=\"checkbox\"]", "[role=\"radio\"]",
        "[role=\"switch\"]", "[role=\"slider\"]", "[role=\"textbox\"]", "[role=\"searchbox\"]",
        "[role=\"combobox\"]", "[role=\"option\"]",
    ].joined(separator: ", ")

    /// A function of a point that says whether the press lands on the
    /// characters of a text node a person can select.
    private static let pressIsOnSelectableText = """
        ((x, y) => {
          let node = null;
          if (document.caretPositionFromPoint) {
            node = document.caretPositionFromPoint(x, y)?.offsetNode ?? null;
          } else if (document.caretRangeFromPoint) {
            node = document.caretRangeFromPoint(x, y)?.startContainer ?? null;
          }
          if (!node || node.nodeType !== Node.TEXT_NODE || !node.textContent.trim()) return false;
          const parent = node.parentElement;
          if (parent && getComputedStyle(parent).userSelect === "none") return false;
          const range = document.createRange();
          range.selectNodeContents(node);
          for (const box of range.getClientRects()) {
            if (x >= box.left && x <= box.right && y >= box.top && y <= box.bottom) return true;
          }
          return false;
        })
        """

    // MARK: - Actions - Window drag

    /// Whether the document leaves a press at `point` to the window: nothing
    /// there takes clicks, its cursor is the plain arrow, and the press is
    /// not on selectable text, so selecting text by dragging still works. The
    /// text test measures the characters' own boxes, so the empty space
    /// beside a heading still moves the window. A page that does not answer
    /// within `windowDragAnswerLimit` keeps the press.
    func leavesPressToWindow(at point: CGPoint) async -> Bool {
        let width = nativeView.bounds.width
        guard width > 0, let takers = try? JSONEncoder().encode(Self.pressTakers) else { return false }
        let source = """
            const scale = innerWidth / \(width);
            const x = \(point.x) * scale, y = \(point.y) * scale;
            const target = document.elementFromPoint(x, y);
            if (!target) return true;
            if (target.closest(\(String(decoding: takers, as: UTF8.self)))) return false;
            const cursor = getComputedStyle(target).cursor;
            if (cursor !== "auto" && cursor !== "default") return false;
            return !\(Self.pressIsOnSelectableText)(x, y);
            """
        guard
            let evaluated = await enginePage.evaluate(source, in: .agent, timeout: Self.windowDragAnswerLimit),
            evaluated.error == nil
        else { return false }
        return evaluated.json == "true"
    }
}
