import Foundation

/// A color as people type it and theme files spell it, `#RRGGBB` or
/// `#RRGGBBAA`, read and written by ``CrestThemeHex``.
extension BrandColor {
    // MARK: - Initializers

    /// The color `text` spells, with or without its `#`, or nil.
    init?(hex text: String) {
        guard let components = CrestThemeHex.components(text) else { return nil }
        self.init(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    // MARK: - Variables

    /// The color as a theme spells it: `#RRGGBB`, or `#RRGGBBAA` when it is
    /// not opaque.
    var hexText: String {
        CrestThemeHex.text(.init(red: red, green: green, blue: blue, alpha: alpha))
    }
}
