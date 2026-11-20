import SwiftUI

/// The row at the top of a temporary window's sidebar that sends its tabs
/// back to the main window. A window on its own lists only its own tabs, so
/// the row says where everything else is and how to get back there.
struct BrowserReturnToMainWindowRow: View {
    // MARK: - Variables

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let capabilities: BrowserInteractionCapabilities
    let action: () -> Void

    private var tabScale: Double { BrowserDeviceAppearanceStore.shared.tabScale }
    private var tabMetrics: BrowserSidebarTabRowMetrics { capabilities.tabRowMetrics }

    private var rowHeight: CGFloat {
        let base = capabilities.rowMinHeight(dynamicTypeSize: dynamicTypeSize)
        return BrowserSidebarDensity(dynamicTypeSize.isAccessibilitySize ? max(1, tabScale) : tabScale).rowHeight(
            base: base, touch: capabilities.supportsTouch)
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text("Return to Main Window")
                    .modifier(BrowserSidebarDensityFont(scale: tabScale, supportsTouch: capabilities.supportsTouch))
                    .lineLimit(1)
            } icon: {
                Image(systemName: "arrow.uturn.backward")
                    .font(tabMetrics.faviconSlot.map { .system(size: $0.glyphSize, weight: $0.glyphWeight) })
                    .frame(width: tabMetrics.faviconSlot?.width ?? 18)
            }
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, capabilities.newTabRowMetrics.labelHorizontalInset)
            .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .crestHoverSurface(cornerRadius: BrowserSidebarMetrics.layerCornerRadius(), showsRestingSurface: true)
        .padding(.horizontal, BrowserSidebarMetrics.layerInset)
        .padding(.top, CrestSpacing.extraSmall)
        .help("Move this window's tabs back to the main window")
        .accessibilityIdentifier("return-to-main-window")
    }
}
