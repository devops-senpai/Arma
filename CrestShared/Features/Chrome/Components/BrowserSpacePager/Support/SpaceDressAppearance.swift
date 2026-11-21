import SwiftUI

// MARK: - Types

/// The colors a Space's dress gives the controls over its sidebar, the
/// address field and the pins, each nil for the window's own.
struct SpaceControlColors: Equatable {
    var fill: BrandColor?
    var fillOpacity: Double = 1
    var text: BrandColor?
    var secondaryText: BrandColor?

    /// The appearance the controls read in, so their icons match the text:
    /// dark under light text and light under dark text, else light over a
    /// light fill and dark over a dark one, and the window's own without
    /// either.
    func colorScheme(over window: ColorScheme) -> ColorScheme {
        if let text { return text.luminance > 0.5 ? .dark : .light }
        guard let fill, fill.alpha * fillOpacity > 0.5 else { return window }
        return fill.luminance > 0.5 ? .light : .dark
    }
}

extension EnvironmentValues {
    /// The colors the Space's dress gives the controls over its sidebar.
    @Entry var spaceControlColors = SpaceControlColors()

    /// The color laid over every surface layer here, before its own tint: a
    /// Space's fill for the controls over its sidebar, or nil for none.
    @Entry var crestSurfaceFill: Color? = nil
}

/// What a Space's dress sets on the content of its sidebar, beside the scheme
/// ``SpaceColorScheme`` gives it: the text colors it chose, the colors of the
/// controls over the sidebar, and the theme of the popovers presented from it.
/// A look without a dress leaves the content as it was.
struct SpaceDressAppearance: ViewModifier {
    let branding: SpaceBranding?

    func body(content: Content) -> some View {
        content
            .modifier(
                SpaceTextColor(color: branding?.sidebarTextColor, secondary: branding?.sidebarSecondaryTextColor)
            )
            .environment(
                \.spaceControlColors,
                SpaceControlColors(
                    fill: branding?.controlsFillColor, fillOpacity: branding?.controlsFillOpacity ?? 1,
                    text: branding?.controlsTextColor, secondaryText: branding?.controlsSecondaryTextColor)
            )
            .environment(\.crestFlyoutTheme, CrestFlyoutTheme(look: branding))
    }
}

/// The controls over a Space's sidebar in the colors its dress gives them:
/// their fill on each surface layer, their text and quieter text, and the
/// appearance that reads with them. Applied inside ``SurfaceToneAppearance``,
/// so what the dress chooses wins over the surface tone's own.
struct SpaceControlsAppearance: ViewModifier {
    @Environment(\.spaceControlColors) private var controls
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if controls == SpaceControlColors() {
            content
        } else {
            labels(content)
                .environment(\.crestSurfaceFill, controls.fill.map { $0.color.opacity(controls.fillOpacity) })
                .environment(\.colorScheme, controls.colorScheme(over: colorScheme))
        }
    }

    @ViewBuilder
    private func labels(_ content: Content) -> some View {
        if let secondary = controls.secondaryText?.color {
            content.foregroundStyle(controls.text?.color ?? Color.primary, secondary)
        } else if let text = controls.text?.color {
            content.foregroundStyle(text)
        } else {
            content
        }
    }
}

/// Draws content's text in `color` when a Space chose one, else as the
/// scheme has it. Secondary text, such as New Tab, draws in `secondary` when
/// the Space chose that, else it and tertiary text follow the color at their
/// usual strengths.
struct SpaceTextColor: ViewModifier {
    let color: BrandColor?
    var secondary: BrandColor? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        if let secondary {
            content.foregroundStyle(color?.color ?? Color.primary, secondary.color)
        } else if let color {
            content.foregroundStyle(color.color)
        } else {
            content
        }
    }
}
