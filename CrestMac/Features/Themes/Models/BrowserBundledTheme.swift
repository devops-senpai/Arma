import Foundation

/// A theme Arma ships with, which the theme library offers beside the themes
/// a person saved and setup offers on its look page: each made to welcome
/// someone, Arc's people, coders, or those who want to make a browser their
/// own. Most are the core's schemes, whose looks every device knows; a theme
/// with a picture is a theme file in the app's resources.
///
/// Each keeps the identity a library saved its copy under before the themes
/// were schemes, so a Space that wears one still finds it.
struct BrowserBundledTheme: Identifiable, Sendable {
    // MARK: - Static Variables

    static let arcSky = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E01", scheme: .arcSky,
        pitch: "Light and airy, for anyone coming from Arc")
    static let arcBlush = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E08", scheme: .arcBlush,
        pitch: "Soft pink by day and deep berry by night")
    static let catppuccin = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E02", scheme: .latteMocha,
        pitch: "Catppuccin Latte by day and Mocha by night")
    static let latte = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E07", scheme: .latte,
        pitch: "Catppuccin's light flavor, with sky-blue folders")
    static let macchiato = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E03", scheme: .macchiato,
        pitch: "Catppuccin's soft dark flavor, for long sessions")
    static let mocha = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E05", scheme: .mocha,
        pitch: "Catppuccin's darkest flavor, with warm peach folders")
    static let frappe = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E06", scheme: .frappe,
        pitch: "Catppuccin's muted middle flavor, with teal folders")
    static let jellyFish = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E04", resource: "JellyFish",
        pitch: "A picture behind your tabs, made your own")
    static let textured = BrowserBundledTheme(
        id: "A2C0B1E5-5A11-4C3B-9F1E-0A7C5B1D2E09", resource: "Textured",
        pitch: "Macchiato's glow and a fine hatch behind your tabs")

    /// Every bundled theme, in the order setup offers them.
    static let all = [arcSky, arcBlush, latte, catppuccin, macchiato, mocha, frappe, jellyFish, textured]

    // MARK: - Variables

    let id: UUID
    /// One line on who the theme is for, under it in setup.
    let pitch: LocalizedStringResource
    /// The theme as a file holds it, read when asked.
    private let source: @Sendable () -> CrestTheme?

    /// The theme, or nil when the app lacks its file.
    var theme: CrestTheme? { source() }

    /// The theme's name as the theme names itself.
    var name: String { theme?.name ?? String(localized: "Untitled Theme") }

    // MARK: - Initializers

    /// A theme of the core's `scheme`, its dark look included.
    private init(id: String, scheme: SpaceScheme, pitch: LocalizedStringResource) {
        self.id = Self.identity(id)
        self.pitch = pitch
        source = {
            CrestTheme(look: scheme.look, dark: scheme.darkLook).named(String(localized: scheme.title))
        }
    }

    /// A theme of the file `resource` in the app's resources.
    private init(id: String, resource: String, pitch: LocalizedStringResource) {
        self.id = Self.identity(id)
        self.pitch = pitch
        source = {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
                let data = try? Data(contentsOf: url)
            else { return nil }
            return try? CrestTheme(json: data)
        }
    }

    // MARK: - Actions - Lookup

    /// The bundled theme kept under `id`, or nil.
    static func named(_ id: UUID) -> BrowserBundledTheme? {
        all.first { $0.id == id }
    }

    private static func identity(_ text: String) -> UUID {
        guard let id = UUID(uuidString: text) else { preconditionFailure("A bundled theme's identity is a UUID") }
        return id
    }
}
