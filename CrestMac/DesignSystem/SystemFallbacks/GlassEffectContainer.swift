import SwiftUI

/// SwiftUI's `GlassEffectContainer` needs macOS 26. This one takes its name in
/// the Mac targets: it is the system's container on macOS 26, and on macOS 15,
/// where there is no glass to merge, only its content.
struct GlassEffectContainer<Content: View>: View {
    // MARK: - Variables

    private let spacing: CGFloat?
    private let content: Content

    // MARK: - Initializers

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            SwiftUI.GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
