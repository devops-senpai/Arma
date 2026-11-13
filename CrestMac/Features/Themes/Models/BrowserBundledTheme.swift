import Foundation

/// A theme Arma ships with, as a theme file in its resources, saved into
/// the theme library on first launch and offered by setup: each made to
/// welcome someone, Arc's people, coders, or those who want to make a
/// browser their own.
struct BrowserBundledTheme: Identifiable, Sendable {
    // MARK: - Static Variables

    static let arcSky = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E01")!, resource: "ArcSky",
        pitch: "Light and airy, for anyone coming from Arc")
    static let arcBlush = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E08")!, resource: "ArcBlush",
        pitch: "Soft pink by day and deep berry by night")
    static let catppuccin = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E02")!, resource: "CatppuccinLatteMocha",
        pitch: "Catppuccin Latte by day and Mocha by night")
    static let latte = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E07")!, resource: "CatppuccinLatte",
        pitch: "Catppuccin's light flavor, with sky-blue folders")
    static let macchiato = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E03")!, resource: "CatppuccinMacchiato",
        pitch: "Catppuccin's soft dark flavor, for long sessions")
    static let mocha = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E05")!, resource: "CatppuccinMocha",
        pitch: "Catppuccin's darkest flavor, with warm peach folders")
    static let frappe = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E06")!, resource: "CatppuccinFrappe",
        pitch: "Catppuccin's muted middle flavor, with teal folders")
    static let jellyFish = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E04")!, resource: "JellyFish",
        pitch: "A picture behind your tabs, made your own")
    static let textured = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E09")!, resource: "Textured",
        pitch: "Macchiato's glow and a fine hatch behind your tabs")
    /// The Heraldic and Modern looks as themes, so they can be edited and put
    /// on any Space; setup offers the looks themselves.
    static let heraldic = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E0A")!, resource: "Heraldic",
        pitch: "The heraldic look, as a theme", offeredBySetup: false)
    static let modern = BrowserBundledTheme(
        id: UUID(uuidString: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E0B")!, resource: "Modern",
        pitch: "The modern look, as a theme", offeredBySetup: false)

    /// The theme a Space wears when nobody chose one for it.
    static let `default` = latte

    /// Every bundled theme, in the order setup offers them.
    static let all = [
        arcSky, arcBlush, latte, catppuccin, macchiato, mocha, frappe, jellyFish, textured, heraldic, modern,
    ]

    /// The bundled themes setup's Pick your look page offers beside the
    /// Heraldic and Modern looks.
    static var offeredBySetup: [BrowserBundledTheme] { all.filter(\.offeredBySetup) }

    // MARK: - Variables

    let id: UUID
    /// The theme file's name in the app's resources.
    let resource: String
    /// One line on who the theme is for, under it in setup.
    let pitch: LocalizedStringResource
    /// Whether setup offers the theme; a theme of a look setup already
    /// offers is not shown twice.
    var offeredBySetup = true

    /// The theme its file holds, or nil when the app lacks it.
    var theme: CrestTheme? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? CrestTheme(json: data)
    }

    /// The theme's name as its file names it.
    var name: String { theme?.name ?? resource }
}
