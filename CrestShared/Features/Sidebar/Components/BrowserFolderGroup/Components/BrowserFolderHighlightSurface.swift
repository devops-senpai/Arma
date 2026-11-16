import SwiftUI

extension EnvironmentValues {
    @Entry var folderPreviewShowsHighlight = false
    @Entry var folderUsesContrastingForeground = false
    @Entry var folderBackgroundColor: BrandColor? = nil
}

/// Shared by live folder groups and the inline settings preview.
struct BrowserFolderHighlightSurface: ViewModifier {
    let color: BrandColor
    /// The color the fill takes instead of `color`; the border keeps `color`.
    var highlightColor: BrandColor? = nil
    /// How opaque the fill is.
    var highlightOpacity: Double = 1
    var textColorMode: SpaceTextColorMode = .automatic
    var showsFill = true
    var showsBorders = true
    /// How many folders hold this one. Each steps the surface in by the
    /// container padding and rounds it one padding tighter, concentric with
    /// the folder around it.
    var depth = 0
    /// Whether the surface steps itself in from the sidebar's edges by its
    /// depth, or fills content that already stands in place.
    var insetsSurface = true
    var isSelected = false
    var emphasisOpacity: Double = 0

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.deviceColorScheme) private var deviceColorScheme
    @Environment(\.folderBackgroundColor) private var parentBackgroundColor

    private var foregroundScheme: ColorScheme {
        if let override = textColorMode.foregroundTone(system: BrowserSpaceForegroundTone(readingIn: colorScheme)) {
            return override == .light ? .dark : .light
        }
        guard showsFill else { return colorScheme }
        return compositedColor.foregroundTone.colorScheme
    }

    private var fillColor: BrandColor { highlightColor ?? color }

    private var compositedColor: BrandColor {
        // The tint lies over the material, which reads in its material color.
        let surfaceScheme = CrestSurfaceTone.shownScheme(over: colorScheme, window: deviceColorScheme)
        let channel = surfaceScheme == .dark ? 0.0 : 1.0
        return fillColor.composited(
            opacity: fillOpacity,
            over: parentBackgroundColor ?? BrandColor(red: channel, green: channel, blue: channel))
    }

    /// Reduced transparency keeps the fill at least as solid as it draws
    /// its quietest tint.
    private var fillOpacity: Double {
        let opacity = highlightOpacity.isFinite ? min(max(highlightOpacity, 0), 1) : 1
        return reduceTransparency ? max(opacity, 0.28) : opacity
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: BrowserSidebarMetrics.layerCornerRadius(depth: depth), style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background {
                if showsFill {
                    CrestSurfaceLayer(shape: shape, tint: fillColor.color.opacity(fillOpacity))
                        .overlay {
                            if emphasisOpacity > 0 { shape.fill(.primary.opacity(emphasisOpacity)) }
                        }
                        .overlay {
                            if isSelected { shape.fill(CrestColor.hover) }
                        }
                        .overlay {
                            if showsBorders {
                                shape.strokeBorder(color.color.opacity(0.5), lineWidth: 1)
                            }
                        }
                        .padding(.leading, insetsSurface ? BrowserFolderLayout.surfaceLeadingInset(depth: depth) : 0)
                        .padding(.trailing, insetsSurface ? BrowserSidebarMetrics.layerInset : 0)
                        .allowsHitTesting(false)
                }
            }
            .environment(\.colorScheme, foregroundScheme)
            .environment(\.folderUsesContrastingForeground, textColorMode != .automatic || showsFill)
            .environment(\.folderBackgroundColor, showsFill ? compositedColor : parentBackgroundColor)
    }
}
