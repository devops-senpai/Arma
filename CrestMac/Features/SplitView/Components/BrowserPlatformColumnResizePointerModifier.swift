import SwiftUI

/// macOS owns real column- and row-resize pointers, so the divider can say what
/// it does before anyone grabs it.
///
/// `pointerStyle(_:)` and `PointerStyle.columnResize` are macOS 15 and later,
/// well under Crest's macOS 26.1 deployment target, so the affordance needs no
/// availability fork of its own — only the platform fork this file is.
struct BrowserPlatformColumnResizePointerModifier: ViewModifier {
    var axis: SplitAxis = .horizontal

    func body(content: Content) -> some View {
        content.pointerStyle(axis.isHorizontal ? .columnResize : .rowResize)
    }
}
