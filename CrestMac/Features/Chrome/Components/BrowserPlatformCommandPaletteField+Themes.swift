import AppKit
import SwiftUI

extension BrowserPlatformCommandPaletteField {
    // MARK: - Actions - Appearance

    /// The text, placeholder and completion suffix are AppKit's, so they read
    /// the field's appearance rather than SwiftUI's scheme: a Space's dark
    /// palette in a light window would otherwise draw dark on dark.
    static func matchAppearance(of field: NSTextField, to colorScheme: ColorScheme) {
        let name: NSAppearance.Name = colorScheme == .dark ? .darkAqua : .aqua
        if field.appearance?.name != name { field.appearance = NSAppearance(named: name) }
    }
}

extension BrowserPlatformCommandPaletteField.Coordinator {
    // MARK: - Actions - Placeholder

    /// Shows the field's placeholder, in the Space's system text color when its
    /// theme names one, else in AppKit's own. Setting either placeholder ends
    /// the field's editing session and starts another, whose begin and end
    /// callbacks refresh it again, so each is set only when it changes.
    func showPlaceholder(_ text: String) {
        guard let field else { return }
        guard let color = model.space?.settings.shownLook.sidebarSecondaryTextColor else {
            if field.placeholderString != text { field.placeholderString = text }
            return
        }
        let ink = NSColor(color.color).usingColorSpace(.sRGB)
        let font = field.font ?? .preferredFont(forTextStyle: .title2)
        if let shown = field.placeholderAttributedString, shown.string == text,
            let shownInk = shown.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor,
            shownInk.usingColorSpace(.sRGB) == ink
        {
            return
        }
        field.placeholderAttributedString = NSAttributedString(
            string: text, attributes: [.foregroundColor: ink ?? NSColor(color.color), .font: font])
    }
}
