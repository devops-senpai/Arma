import SwiftUI

/// The phone and tablet keep no theme library, so new Spaces wear the look
/// Crest gives them and there is no default theme to choose.
struct BrowserPlatformDefaultThemeSettingsGroup: View {
    let browser: BrowserStore

    var body: some View {
        EmptyView()
    }
}
