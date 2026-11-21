import SwiftUI

/// How the command palette's card looks over this Space: a tint and how far
/// it covers the system material, once for the light appearance and once for
/// the dark. Its Reset leaves both appearances to the material again.
struct BrowserCrestStudioCommandPalette: View {
    let context: BrowserCrestStudioContext

    /// What a light card looks like before a tint is picked.
    private static var lightFallback: BrandColor { BrandColor(red: 1, green: 1, blue: 1) }

    private var resets: [CrestResettableSetting] {
        [
            context.paletteTint(dark: false).resettable("Light tint"),
            context.paletteOpacity(dark: false).resettable("Light opacity"),
            context.paletteTextColor(dark: false).resettable("Light text"),
            context.paletteSelectedTextColor(dark: false).resettable("Light selected text"),
            context.paletteTint(dark: true).resettable("Dark tint"),
            context.paletteOpacity(dark: true).resettable("Dark opacity"),
            context.paletteTextColor(dark: true).resettable("Dark text"),
            context.paletteSelectedTextColor(dark: true).resettable("Dark selected text"),
        ]
    }

    var body: some View {
        Section {
            rows
        } header: {
            HStack {
                Text("Command Palette")
                Spacer()
                BrowserCrestStudioResetButton(title: "Command Palette", settings: resets)
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        surfaceRows(dark: false)
        surfaceRows(dark: true)
    }

    /// The tint, opacity, text and selected row's text of the appearance
    /// `dark` names. The opacity has nothing to cover until a tint is picked;
    /// the selected row lies on paper, so its text falls back to ink.
    @ViewBuilder
    private func surfaceRows(dark: Bool) -> some View {
        let tint = context.paletteTint(dark: dark)
        BrowserCrestStudioColorPickerRow(
            title: dark ? "Dark tint" : "Light tint", value: tint, fallback: dark ? .ink : Self.lightFallback)
        BrowserCrestStudioSlider(
            title: dark ? "Dark opacity" : "Light opacity", value: context.paletteOpacity(dark: dark)
        )
        .disabled(tint.wrappedValue == nil)
        BrowserCrestStudioColorPickerRow(
            title: dark ? "Dark text" : "Light text", value: context.paletteTextColor(dark: dark),
            fallback: .text(for: dark ? .light : .dark))
        BrowserCrestStudioColorPickerRow(
            title: dark ? "Dark selected text" : "Light selected text",
            value: context.paletteSelectedTextColor(dark: dark), fallback: .ink)
    }
}
