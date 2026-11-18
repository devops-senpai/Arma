import SwiftUI

extension BrowserCrestStudioContext {
    // MARK: - Actions - Settings

    /// A setting whose default is `defaultValue` whatever the starting look
    /// holds, such as a color a Space leaves unchosen.
    func setting<Value: Equatable>(_ path: WritableKeyPath<SpaceBranding, Value>, default defaultValue: Value)
        -> CrestSettingValue<Value>
    {
        CrestSettingValue(setting(path).binding, default: defaultValue)
    }
}

extension EnvironmentValues {
    /// The settings the Studio group here puts back with its Reset, or none
    /// for a group that offers no Reset.
    @Entry var browserCrestStudioResets: [CrestResettableSetting] = []
}

/// One group's Reset: puts every setting the group owns back to its default,
/// and offers nothing while they all still hold it. A group with no
/// settings to reset shows no Reset at all.
struct BrowserCrestStudioResetButton: View {
    let title: LocalizedStringResource
    let settings: [CrestResettableSetting]

    var body: some View {
        if !settings.isEmpty {
            Button("Reset") { settings.resetAll() }
                .buttonStyle(.borderless)
                .disabled(!settings.isModified)
                .accessibilityLabel(Text("Reset \(Text(title)) to default"))
        }
    }
}

/// A color a Space may leave unchosen: the swatch shows `fallback` until a
/// color is picked in the wheel it opens, where each change applies as it
/// is made, and the row's reset lets the color go again.
struct BrowserCrestStudioColorPickerRow: View {
    let title: LocalizedStringKey
    let value: CrestSettingValue<BrandColor?>
    let fallback: BrandColor

    @State private var isOpen = false

    var body: some View {
        CrestSettingRow(title, setting: value.resettable(title)) {
            Button {
                isOpen.toggle()
            } label: {
                Capsule()
                    .fill((value.wrappedValue ?? fallback).color)
                    .frame(width: 44, height: 22)
                    .overlay { Capsule().strokeBorder(.primary.opacity(0.18)) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(title))
            .crestPopover(isPresented: $isOpen, arrowEdge: .trailing) {
                BrowserColorWheelPicker(
                    color: Binding(get: { value.wrappedValue ?? fallback }, set: { value.binding.wrappedValue = $0 }),
                    title: title
                )
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

/// The sidebar's own text colors, which a Space may leave to its text mode:
/// the tabs' text and the quieter system text, each shown as the tab text
/// the window draws until one is picked.
struct BrowserCrestStudioSidebarTextColors: View {
    let context: BrowserCrestStudioContext

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BrowserCrestStudioColorPickerRow(
            title: "Text color", value: context.setting(\.sidebarTextColor, default: nil),
            fallback: context.value.sidebarTextColor(over: colorScheme))
        BrowserCrestStudioColorPickerRow(
            title: "System text color", value: context.setting(\.sidebarSecondaryTextColor, default: nil),
            fallback: context.value.sidebarTextColor(over: colorScheme))
    }
}
