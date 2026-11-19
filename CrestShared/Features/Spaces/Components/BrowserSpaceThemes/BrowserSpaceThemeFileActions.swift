import SwiftUI

/// What a shell offers for a Space's look as a shareable file: writing it out
/// and loading one in, each answering what went wrong or nil. A shell with
/// no file panels, such as a phone, offers none and the Forge shows nothing.
struct BrowserSpaceThemeFileActions {
    // MARK: - Variables

    let export: @MainActor () async -> String?
    let load: @MainActor () async -> String?
}

/// The theme a Forge edits in place of a Space's look, as Settings › Themes
/// shows it: the symbol its small window shows, and where its picture is
/// kept, which the Forge's stage draws and its Sidebar step edits.
struct BrowserThemeForgeSubject {
    // MARK: - Variables

    let symbol: String
    /// The appearance the stage's small window is drawn in.
    let appearance: ColorScheme
    /// Where the theme's picture is kept, and what to do after each change.
    let backdrop: BrowserSpaceBackdropSection.Target
}

extension EnvironmentValues {
    @Entry var browserSpaceThemeFiles: BrowserSpaceThemeFileActions? = nil
    /// The theme the Forge here edits, or nil for a Space's own look.
    @Entry var browserThemeForgeSubject: BrowserThemeForgeSubject? = nil
}
