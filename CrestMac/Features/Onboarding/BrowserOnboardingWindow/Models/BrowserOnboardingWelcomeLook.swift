import Foundation

/// The welcome page's look: Catppuccin Frappé's base as a solid field under
/// Arma's own arms, so the welcome shows Arma's logo and stays dark enough
/// for its light text.
enum BrowserOnboardingWelcomeLook {
    // MARK: - Static Variables

    /// Frappé's base, mauve and blue.
    static let all: [SpaceBranding] = [look(base: 0x303446, mauve: 0xCA9EE6, blue: 0x8CAAEE)]

    // MARK: - Actions - Looks

    /// The welcome's look `index` turns into, round and round.
    static func look(at index: Int) -> SpaceBranding {
        all[index % all.count]
    }

    /// A flavor's base as a solid field, with the logo's guidon, pale and
    /// bird as the crest in its mauve and blue.
    private static func look(base: Int, mauve: Int, blue: Int) -> SpaceBranding {
        var look = SpaceHouse.winter.look
        look.colors = ColorPalette(colors: [color(base), color(mauve), color(blue)])
        look.themeMode = .banner
        look.bannerPattern = .solid
        look.bannerStrength = 1
        look.crest.backplate = .flag
        look.crest.ordinary = .pale
        look.crest.symbol = .sparrow
        look.crest.charge = nil
        return look.normalized()
    }

    private static func color(_ hex: Int) -> BrandColor {
        BrandColor(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: 1)
    }
}
