import Foundation

extension SpaceBranding {
    // MARK: - Static Variables

    /// The welcome page's look: Catppuccin Frappé's base as a solid field
    /// under Arma's own arms (the logo's guidon, pale and bird) in its mauve
    /// and blue, so the welcome shows Arma's logo and stays dark enough for
    /// its light text.
    static let armaWelcome: SpaceBranding = {
        var look = SpaceHouse.winter.look
        look.colors = ColorPalette(colors: [hex(0x303446), hex(0xCA9EE6), hex(0x8CAAEE)])
        look.themeMode = .banner
        look.bannerPattern = .solid
        look.bannerStrength = 1
        look.crest.backplate = .flag
        look.crest.ordinary = .pale
        look.crest.symbol = .sparrow
        look.crest.charge = nil
        return look.normalized()
    }()

    // MARK: - Actions - Colors

    private static func hex(_ value: Int) -> BrandColor {
        BrandColor(
            red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255, alpha: 1)
    }
}
