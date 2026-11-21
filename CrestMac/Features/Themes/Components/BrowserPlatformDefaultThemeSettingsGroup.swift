import SwiftUI

/// The theme new Spaces wear on this Mac, and the Spaces that follow it: any
/// theme in the library, or none for the look Crest gives them. Choosing one
/// dresses every Space that wears the previous default, or no theme in the
/// look it started with.
struct BrowserPlatformDefaultThemeSettingsGroup: View {
    // MARK: - Variables

    let browser: BrowserStore

    @State private var library = BrowserThemeLibrary.shared

    // MARK: - Actions - Presentation

    var body: some View {
        let resettable = CrestResettableSetting(title: "Default theme", isDefault: library.defaultThemeID == nil) {
            library.chooseDefaultTheme(nil, in: browser.profileSettingsBrowser)
        }
        CrestSettingsGroup("Themes", settings: [resettable]) {
            CrestSettingRow("Default theme", setting: resettable) {
                Picker("Default theme", selection: choice) {
                    Text("None").tag(UUID?.none)
                    Divider()
                    ForEach(library.entries) { entry in
                        Text(entry.name).tag(UUID?.some(entry.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("default-theme")
            }
        }
    }

    private var choice: Binding<UUID?> {
        Binding(
            get: { library.defaultThemeID },
            set: { library.chooseDefaultTheme($0, in: browser.profileSettingsBrowser) })
    }
}
