import SwiftUI

// MARK: - Types

/// The colors a Space's theme gives the controls over its sidebar, the
/// address field and the pins, each nil for the window's own.
struct SpaceControlColors: Equatable {
    var fill: BrandColor?
    var fillOpacity: Double = 1
    var text: BrandColor?
    var secondaryText: BrandColor?

    /// The appearance the controls read in: light over a light fill, dark over
    /// a dark one, and the window's own without a fill that shows.
    func colorScheme(over window: ColorScheme) -> ColorScheme {
        guard let fill, fill.alpha * fillOpacity > 0.5 else { return window }
        return fill.luminance > 0.5 ? .light : .dark
    }
}

extension EnvironmentValues {
    /// The scheme the window draws in, under any Space's own: what controls
    /// that read the same on every Space wear.
    @Entry var deviceColorScheme: ColorScheme? = nil
    /// The colors the Space's theme gives the controls over its sidebar.
    @Entry var spaceControlColors = SpaceControlColors()
}

/// Draws content in the scheme a Space's sidebar reads in over the window,
/// and in the one text color the Space chose, when it chose one, keeping the
/// window's own scheme for the controls that read the same on every Space.
/// Popovers presented from the content wear the Space's popover colors.
///
/// The scheme follows the device's dark dimming, which a person drags. Working
/// it out here, rather than in the view that wraps the sidebar, keeps a drag to
/// this modifier: the sidebar under it re-renders only when the scheme itself
/// changes.
struct SpaceColorScheme: ViewModifier {
    /// The look of the Space the content belongs to, or nil for none, which
    /// draws dark.
    let branding: SpaceBranding?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.deviceColorScheme) private var deviceColorScheme

    func body(content: Content) -> some View {
        content
            .modifier(
                SpaceTextColor(color: branding?.sidebarTextColor, secondary: branding?.sidebarSecondaryTextColor)
            )
            .environment(\.colorScheme, branding?.shown.colorScheme(over: colorScheme) ?? .dark)
            .environment(\.deviceColorScheme, deviceColorScheme ?? colorScheme)
            .environment(
                \.spaceControlColors,
                SpaceControlColors(
                    fill: branding?.controlsFillColor, fillOpacity: branding?.controlsFillOpacity ?? 1,
                    text: branding?.controlsTextColor, secondaryText: branding?.controlsSecondaryTextColor)
            )
            .environment(
                \.crestFlyoutColors,
                CrestFlyoutColors(
                    background: branding?.popoverBackgroundColor, text: branding?.popoverTextColor,
                    secondaryText: branding?.popoverSecondaryTextColor, accent: branding?.popoverAccentColor,
                    accentOpacity: branding?.popoverAccentOpacity ?? 1, button: branding?.popoverButtonColor,
                    buttonOutline: branding?.popoverButtonOutlineColor))
    }
}

/// Glass controls over a Space's sidebar, such as the address field, the
/// pins and the site controls they open, in the window's own light or dark
/// with its own text color, the same on every Space whatever its colors,
/// unless the Space's theme colors them.
struct DeviceSurfaceAppearance: ViewModifier {
    @Environment(\.deviceColorScheme) private var deviceColorScheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.spaceControlColors) private var controls

    func body(content: Content) -> some View {
        content
            // The label color itself, not the Space ink a hierarchical style
            // would take its levels from, or the theme's two text colors.
            .modifier(Labels(controls: controls))
            .environment(\.spaceChromeForeground, nil)
            .environment(\.crestSurfaceFill, controls.fill.map { $0.color.opacity(controls.fillOpacity) })
            .environment(\.colorScheme, controls.colorScheme(over: deviceColorScheme ?? colorScheme))
    }

    /// The text color, and the quieter one when the theme names it.
    private struct Labels: ViewModifier {
        let controls: SpaceControlColors

        func body(content: Content) -> some View {
            let text = controls.text?.color ?? Color.primary
            if let secondary = controls.secondaryText?.color {
                content.foregroundStyle(text, secondary)
            } else {
                content.foregroundStyle(text)
            }
        }
    }
}
