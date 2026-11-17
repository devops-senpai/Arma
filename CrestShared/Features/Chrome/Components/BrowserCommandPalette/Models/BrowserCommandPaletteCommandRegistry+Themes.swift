import Foundation

/// The palette's @themes rows: a saved theme put on the Space the window shows.
extension BrowserCommandPaletteCommandRegistry {
    // MARK: - Actions - Themes

    /// Puts the saved theme `id` on the Space the window shows.
    func applyTheme(_ id: UUID) {
        themeApplier(id)
    }
}
