import SwiftUI

/// The colors a Space's theme gives the flyouts its window presents, such as
/// Site Controls: a fill laid over the flyout surface, the labels' color and
/// their quieter color, the accent, and the fill and outline of plain
/// buttons. Each color left nil keeps the surface's own; a flyout without a
/// theme draws as ``CrestFlyoutStyle`` always does.
struct CrestFlyoutTheme: Equatable, Sendable {
    // MARK: - Variables

    var background: BrandColor?
    var text: BrandColor?
    var secondaryText: BrandColor?
    var accent: BrandColor?
    var accentOpacity: Double = 1
    var button: BrandColor?
    var buttonOutline: BrandColor?

    // MARK: - Initializers

    /// The flyout colors `look` dresses its popovers in, or nil when it
    /// chooses none.
    init?(look: SpaceBranding?) {
        guard let popovers = look?.dress?.popovers else { return nil }
        background = popovers.backgroundColor
        text = popovers.textColor
        secondaryText = popovers.secondaryTextColor
        accent = popovers.accentColor
        accentOpacity = popovers.accentOpacity
        button = popovers.buttonColor
        buttonOutline = popovers.buttonOutlineColor
    }

    // MARK: - Actions - Appearance

    /// The appearance the flyout's labels read in over the theme's fill:
    /// light over a light fill, so the system's labels stay dark on it, and
    /// `standard` otherwise.
    func colorScheme(standard: ColorScheme) -> ColorScheme {
        guard let background, background.alpha > 0.5 else { return standard }
        return background.luminance > 0.5 ? .light : .dark
    }
}

extension EnvironmentValues {
    /// The theme flyouts presented from here wear, or nil for the flyout
    /// surface alone.
    @Entry var crestFlyoutTheme: CrestFlyoutTheme? = nil
}

/// A flyout's content in its Space's theme: labels in the theme's colors,
/// plain buttons on its fill and outline, the accent as the tint, and the
/// appearance its fill reads in. Without a theme the content is left as the
/// flyout style draws it.
struct CrestFlyoutThemeLabels: ViewModifier {
    // MARK: - Variables

    let theme: CrestFlyoutTheme?
    /// The appearance the flyout style draws in without a theme.
    let standardScheme: ColorScheme

    // MARK: - Actions - Drawing

    @ViewBuilder
    func body(content: Content) -> some View {
        if let theme {
            let scheme = theme.colorScheme(standard: standardScheme)
            content
                .modifier(Labels(theme: theme))
                .modifier(Buttons(theme: theme))
                .tint((theme.accent?.color ?? CrestBrandTheme.accent(scheme)).opacity(theme.accentOpacity))
                .environment(\.colorScheme, scheme)
        } else {
            content
        }
    }

    /// The labels in the theme's text color, and the quieter ones in its
    /// secondary text color, or the text color dimmed as the system dims it.
    private struct Labels: ViewModifier {
        let theme: CrestFlyoutTheme

        @ViewBuilder
        func body(content: Content) -> some View {
            if let secondary = theme.secondaryText {
                content.foregroundStyle(theme.text?.color ?? Color.primary, secondary.color)
            } else if let text = theme.text {
                content.foregroundStyle(text.color)
            } else {
                content.foregroundStyle(.primary)
            }
        }
    }

    /// Plain buttons on the theme's button fill and outline, once it chose
    /// either; buttons that pick a style of their own keep it.
    private struct Buttons: ViewModifier {
        let theme: CrestFlyoutTheme

        @ViewBuilder
        func body(content: Content) -> some View {
            if theme.button != nil || theme.buttonOutline != nil {
                content.buttonStyle(CrestFlyoutThemeButtonStyle(theme: theme))
            } else {
                content
            }
        }
    }
}

/// The theme's fill over a flyout surface in `shape`, or nothing without one.
struct CrestFlyoutThemeFill<FillShape: Shape>: View {
    let theme: CrestFlyoutTheme?
    let shape: FillShape

    var body: some View {
        if let background = theme?.background { shape.fill(background.color) }
    }
}
