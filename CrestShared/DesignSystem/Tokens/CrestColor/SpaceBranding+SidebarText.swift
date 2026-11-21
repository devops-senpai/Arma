import SwiftUI

/// The color a Space's sidebar text reads in, as a window draws it.
extension SpaceBranding {
    // MARK: - Actions - Text

    /// The color the Space's sidebar text reads in over a window in
    /// `appearance`: the chosen one, or plain text in its tone.
    func sidebarTextColor(over appearance: ColorScheme) -> BrandColor {
        sidebarTextColor ?? .text(for: foregroundTone(over: appearance))
    }
}

extension BrandColor {
    // MARK: - Actions - Text

    /// Plain text in `tone`: white for light text, near black for dark.
    static func text(for tone: BrowserSpaceForegroundTone) -> BrandColor {
        tone == .light ? BrandColor(red: 1, green: 1, blue: 1) : BrandColor(red: 0.1, green: 0.1, blue: 0.12)
    }
}
