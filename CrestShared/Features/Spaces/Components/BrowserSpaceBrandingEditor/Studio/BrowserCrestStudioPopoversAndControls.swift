import SwiftUI

/// The Forge's sections for what a Space dresses beyond its sidebar: the
/// popovers its window presents, and the address field and pins over its
/// sidebar. Each color a Space leaves unchosen shows what draws in its place:
/// the flyout surface's own, or the window's.
struct BrowserCrestStudioPopoversAndControls: View {
    // MARK: - Variables

    let context: BrowserCrestStudioContext

    @Environment(\.self) private var environment

    private var branding: SpaceBranding { context.value }

    /// The flyout surface's own fill, labels and accent, as it draws them.
    private var flyoutBackground: BrandColor { resolved(CrestColor.windowBackground, in: .dark) }
    private var flyoutText: BrandColor { resolved(.primary, in: .dark) }
    private var flyoutAccent: BrandColor { resolved(CrestBrandTheme.accent(.dark), in: .dark) }

    // MARK: - Actions - Presentation

    var body: some View {
        Section {
            BrowserCrestStudioColorPickerRow(
                title: "Background color", value: context.setting(\.popoverBackgroundColor, default: nil),
                fallback: flyoutBackground)
            BrowserCrestStudioColorPickerRow(
                title: "Text color", value: context.setting(\.popoverTextColor, default: nil), fallback: flyoutText)
            BrowserCrestStudioColorPickerRow(
                title: "Secondary text color", value: context.setting(\.popoverSecondaryTextColor, default: nil),
                fallback: branding.popoverTextColor ?? flyoutText)
            BrowserCrestStudioColorPickerRow(
                title: "Accent color", value: context.setting(\.popoverAccentColor, default: nil),
                fallback: flyoutAccent)
            BrowserCrestStudioSlider(
                title: "Accent opacity", value: context.setting(\.popoverAccentOpacity, default: 1))
            BrowserCrestStudioColorPickerRow(
                title: "Button color", value: context.setting(\.popoverButtonColor, default: nil),
                fallback: branding.popoverBackgroundColor ?? flyoutBackground)
            BrowserCrestStudioColorPickerRow(
                title: "Button outline color", value: context.setting(\.popoverButtonOutlineColor, default: nil),
                fallback: branding.popoverAccentColor ?? flyoutAccent)
        } header: {
            Text("Popovers")
        }
        Section {
            BrowserCrestStudioColorPickerRow(
                title: "Fill color", value: context.setting(\.controlsFillColor, default: nil),
                fallback: branding.primaryColor)
            BrowserCrestStudioSlider(
                title: "Fill opacity", value: context.setting(\.controlsFillOpacity, default: 1))
            BrowserCrestStudioColorPickerRow(
                title: "Text color", value: context.setting(\.controlsTextColor, default: nil), fallback: flyoutText)
            BrowserCrestStudioColorPickerRow(
                title: "Secondary text color", value: context.setting(\.controlsSecondaryTextColor, default: nil),
                fallback: branding.controlsTextColor ?? flyoutText)
        } header: {
            Text("Address field and pins")
        }
    }

    // MARK: - Actions - Colors

    /// `color` as it draws in `scheme`, as a color a Space keeps.
    private func resolved(_ color: Color, in scheme: ColorScheme) -> BrandColor {
        var appearance = environment
        appearance.colorScheme = scheme
        let resolved = color.resolve(in: appearance)
        return BrandColor(
            red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue),
            alpha: Double(resolved.opacity))
    }
}
