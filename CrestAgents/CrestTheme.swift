import Foundation

// A Space's look as a document people share: JSON holding the members of a
// Space's branding by the names the session gives them, with colors as hex
// strings, `#RRGGBB` or `#RRGGBBAA`, and the word `default` in a color field
// letting a chosen color go. Every member is optional, so a theme can change
// only what it names. A `dark` object holds the same members for the look the
// Space wears while windows are dark, and `darkLook` says whether it is worn:
// false keeps it in the file, turned off, so turning it back on loses
// nothing. The app turns a theme into a Space's branding.
//
// Files written before version 2 named the members after the sections of the
// first theme editor (`background`, `icon`, `folders`, `commandPalette`,
// `popovers`, `controls`), with a texture that was only on or off; they read
// into the same members, and are written as version 2 when next saved.

/// A theme as the file holds it: the look, and the look for dark windows.
struct CrestTheme: Equatable, Sendable {
    // MARK: - Types

    /// One look as the file holds it: a Space's branding by its members'
    /// names, each left out to keep what the Space has.
    struct Look: Equatable, Sendable {
        /// One to three colors: background, accent, pattern.
        var colors: [String]?
        /// `banner` or `gradient`.
        var themeMode: String?
        /// The banner's pattern, such as `solid` or `diagonal`.
        var bannerPattern: String?
        /// The gradient's direction, in degrees.
        var gradientAngle: Double?
        /// How strongly the colors show, 0 through 1.
        var bannerStrength: Double?
        /// How far the banner fades behind the controls, 0 through 1.
        var readabilityFade: Double?
        var keepsControlsReadable: Bool?
        /// How strongly a grain lies over the sidebar, 0 through 1.
        var textureStrength: Double?
        /// `automatic`, `light`, `dark` or `system`.
        var textColorMode: String?
        /// `simpleSymbol` or `layeredCrest`.
        var iconStyle: String?
        /// The icon's color, or `default` to follow the Space's colors.
        var symbolColor: String?
        /// How strongly folders tint their rows when the dress names no
        /// highlight opacity, 0 through 1.
        var folderColorIntensity: Double?
        var dress: Dress?

        /// Whether the look names anything at all.
        var isEmpty: Bool { self == Look() }
    }

    /// What a look sets beyond its banner and crest, by the names the
    /// session's dress gives them.
    struct Dress: Codable, Equatable, Sendable {
        struct Text: Codable, Equatable, Sendable {
            /// The sidebar's text, or `default` to follow the text color mode.
            var color: String?
            /// Its quieter text, or `default` to dim the text as the system does.
            var secondaryColor: String?
        }

        struct Folders: Codable, Equatable, Sendable {
            /// One folder's colors in place of the Space's, each `default` or
            /// absent to follow them.
            struct Override: Codable, Equatable, Sendable {
                var color: String?
                var backColor: String?
                var outlineColor: String?
            }

            /// The color a folder without one of its own wears, or `default`.
            var color: String?
            /// The color of that folder's back face, or `default` to shade the front.
            var backColor: String?
            /// The line drawn around that folder, or `default` for none.
            var outlineColor: String?
            /// The color that tints a folder's rows while it is open, hovered or
            /// chosen, or `default` for the folder's own color.
            var highlightColor: String?
            /// How opaque that tint is, 0 through 1.
            var highlightOpacity: Double?
            /// Colors for single folders by path, such as `.HomeLab.proxmox`,
            /// replacing every override the Space had.
            var overrides: [String: Override]?
        }

        struct PaletteSurface: Codable, Equatable, Sendable {
            /// The tint over the system material, or `default` for the material alone.
            var tint: String?
            /// How far the tint covers the material, 0 through 1.
            var opacity: Double?
            /// The one color the card's text reads in, or `default` for the system's.
            var textColor: String?
        }

        struct CommandPalette: Codable, Equatable, Sendable {
            var light: PaletteSurface?
            var dark: PaletteSurface?
        }

        /// The popovers the window presents, such as Site Controls.
        struct Popovers: Codable, Equatable, Sendable {
            var backgroundColor: String?
            var textColor: String?
            var secondaryTextColor: String?
            var accentColor: String?
            var accentOpacity: Double?
            var buttonColor: String?
            var buttonOutlineColor: String?
        }

        /// The controls over the sidebar: the address field and the pins.
        struct Controls: Codable, Equatable, Sendable {
            var fillColor: String?
            var fillOpacity: Double?
            var textColor: String?
            var secondaryTextColor: String?
        }

        var text: Text?
        var folders: Folders?
        var commandPalette: CommandPalette?
        var popovers: Popovers?
        var controls: Controls?
    }

    /// The picture behind a Space's sidebar and window, carried in the theme
    /// itself so a theme file brings it along, and how it sits. A theme
    /// without one takes a Space's picture away when it is put on.
    struct BackgroundImage: Codable, Equatable, Sendable {
        /// The picture's bytes, Base64.
        var data: String
        /// The picture's file extension, such as `png` or `jpg`.
        var format: String
        var anchor: String?
        var size: String?
        var growsToWidth: Bool?
        var growsToHeight: Bool?
        var tiles: Bool?
        var imageOpacity: Double?
        var tintOpacity: Double?
        var blur: Double?
        /// Where the sidebar lays its tab backing: `off`, `rows` or `sidebar`.
        var tabBacking: String?
        /// The tab backing's color, or `default` for the Space's own.
        var tabBackingColor: String?
        var tabBackingOpacity: Double?
        var tabBackingBlur: Double?
    }

    // MARK: - Static Variables

    /// The word a color field holds to let a chosen color go.
    static let defaultColorWord = "default"

    /// The version of the file this build writes.
    static let version = 2

    // MARK: - Variables

    var name: String?
    /// The look, or the light look of a pair.
    var look: Look
    /// The look for dark windows, worn in them while `darkLook` says so and
    /// kept, turned off, otherwise; nil when none was ever made.
    var dark: Look?
    /// Whether `dark` is worn. Left out, it is whenever `dark` is there, as
    /// every theme saved before the field meant.
    var darkLook: Bool?
    /// The Space's picture, or nil for none.
    var backgroundImage: BackgroundImage?

    /// Whether the theme wears `dark` in dark windows.
    var hasDarkLook: Bool { dark != nil && darkLook ?? true }

    /// The look for dark windows as worn: nil while the dark look is off.
    var wornDark: Look? { hasDarkLook ? dark : nil }

    /// Whether the theme names anything at all.
    var isEmpty: Bool {
        look.isEmpty && (dark?.isEmpty ?? true) && darkLook == nil && backgroundImage == nil
    }

    // MARK: - Initializers

    init(name: String? = nil, look: Look = Look(), dark: Look? = nil) {
        self.name = name
        self.look = look
        self.dark = dark
    }

    /// The theme a JSON document holds, in either version.
    init(json data: Data) throws {
        self = try JSONDecoder().decode(CrestTheme.self, from: data)
    }

    // MARK: - Actions - Documents

    /// This theme as a version 2 document, its members in a fixed order.
    func json() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    /// This theme named `name`.
    func named(_ name: String) -> CrestTheme {
        var theme = self
        theme.name = name
        return theme
    }
}

// MARK: - Codable

extension CrestTheme: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, name, dark, darkLook, backgroundImage
    }

    /// The top level holds the look's members beside the theme's own.
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        look = try Look(from: decoder)
        dark = try values.decodeIfPresent(Look.self, forKey: .dark)
        darkLook = try values.decodeIfPresent(Bool.self, forKey: .darkLook)
        backgroundImage = try values.decodeIfPresent(BackgroundImage.self, forKey: .backgroundImage)
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(Self.version, forKey: .version)
        try values.encodeIfPresent(name, forKey: .name)
        try look.encode(to: encoder)
        try values.encodeIfPresent(dark, forKey: .dark)
        try values.encodeIfPresent(darkLook, forKey: .darkLook)
        try values.encodeIfPresent(backgroundImage, forKey: .backgroundImage)
    }
}

extension CrestTheme.Look: Codable {
    private enum CodingKeys: String, CodingKey {
        case colors, themeMode, bannerPattern, gradientAngle, bannerStrength, readabilityFade, keepsControlsReadable
        case textureStrength, textColorMode, iconStyle, symbolColor, folderColorIntensity, dress
    }

    /// The sections a file before version 2 held the same members in.
    private enum FirstVersionKeys: String, CodingKey {
        case background, icon, folders, commandPalette, popovers, controls
    }

    private struct FirstVersionBackground: Decodable {
        var colors: [String]?
        var style: String?
        var pattern: String?
        var angle: Double?
        var intensity: Double?
        var readabilityFade: Double?
        var texture: Bool?
        var textColor: String?
        var sidebarText: String?
        var sidebarSecondaryText: String?
    }

    private struct FirstVersionIcon: Decodable {
        var color: String?
    }

    private struct FirstVersionFolders: Decodable {
        var color: String?
        var backColor: String?
        var outlineColor: String?
        var intensity: Double?
        var highlightColor: String?
        var highlightOpacity: Double?
        var overrides: [String: CrestTheme.Dress.Folders.Override]?
    }

    private struct FirstVersionSurface: Decodable {
        var tint: String?
        var opacity: Double?
        var text: String?

        var surface: CrestTheme.Dress.PaletteSurface {
            CrestTheme.Dress.PaletteSurface(tint: tint, opacity: opacity, textColor: text)
        }
    }

    private struct FirstVersionPalette: Decodable {
        var light: FirstVersionSurface?
        var dark: FirstVersionSurface?
    }

    private struct FirstVersionPopovers: Decodable {
        var background: String?
        var text: String?
        var secondaryText: String?
        var accent: String?
        var accentOpacity: Double?
        var button: String?
        var buttonOutline: String?
    }

    private struct FirstVersionControls: Decodable {
        var fill: String?
        var fillOpacity: Double?
        var text: String?
        var secondaryText: String?
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        colors = try values.decodeIfPresent([String].self, forKey: .colors)
        themeMode = try values.decodeIfPresent(String.self, forKey: .themeMode)
        bannerPattern = try values.decodeIfPresent(String.self, forKey: .bannerPattern)
        gradientAngle = try values.decodeIfPresent(Double.self, forKey: .gradientAngle)
        bannerStrength = try values.decodeIfPresent(Double.self, forKey: .bannerStrength)
        readabilityFade = try values.decodeIfPresent(Double.self, forKey: .readabilityFade)
        keepsControlsReadable = try values.decodeIfPresent(Bool.self, forKey: .keepsControlsReadable)
        textureStrength = try values.decodeIfPresent(Double.self, forKey: .textureStrength)
        textColorMode = try values.decodeIfPresent(String.self, forKey: .textColorMode)
        iconStyle = try values.decodeIfPresent(String.self, forKey: .iconStyle)
        symbolColor = try values.decodeIfPresent(String.self, forKey: .symbolColor)
        folderColorIntensity = try values.decodeIfPresent(Double.self, forKey: .folderColorIntensity)
        dress = try values.decodeIfPresent(CrestTheme.Dress.self, forKey: .dress)
        try readFirstVersion(from: decoder)
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(colors, forKey: .colors)
        try values.encodeIfPresent(themeMode, forKey: .themeMode)
        try values.encodeIfPresent(bannerPattern, forKey: .bannerPattern)
        try values.encodeIfPresent(gradientAngle, forKey: .gradientAngle)
        try values.encodeIfPresent(bannerStrength, forKey: .bannerStrength)
        try values.encodeIfPresent(readabilityFade, forKey: .readabilityFade)
        try values.encodeIfPresent(keepsControlsReadable, forKey: .keepsControlsReadable)
        try values.encodeIfPresent(textureStrength, forKey: .textureStrength)
        try values.encodeIfPresent(textColorMode, forKey: .textColorMode)
        try values.encodeIfPresent(iconStyle, forKey: .iconStyle)
        try values.encodeIfPresent(symbolColor, forKey: .symbolColor)
        try values.encodeIfPresent(folderColorIntensity, forKey: .folderColorIntensity)
        try values.encodeIfPresent(dress, forKey: .dress)
    }

    /// Fills in the members a file before version 2 named in its sections,
    /// where the file names no member of its own. A texture there was on or
    /// off, which is full strength or none.
    private mutating func readFirstVersion(from decoder: any Decoder) throws {
        let sections = try decoder.container(keyedBy: FirstVersionKeys.self)
        if let background = try sections.decodeIfPresent(FirstVersionBackground.self, forKey: .background) {
            colors = colors ?? background.colors
            themeMode = themeMode ?? background.style
            bannerPattern = bannerPattern ?? background.pattern
            gradientAngle = gradientAngle ?? background.angle
            bannerStrength = bannerStrength ?? background.intensity
            readabilityFade = readabilityFade ?? background.readabilityFade
            textureStrength = textureStrength ?? background.texture.map { $0 ? 1 : 0 }
            textColorMode = textColorMode ?? background.textColor
            if background.sidebarText != nil || background.sidebarSecondaryText != nil {
                editDress { dress in
                    dress.text =
                        dress.text
                        ?? CrestTheme.Dress.Text(
                            color: background.sidebarText, secondaryColor: background.sidebarSecondaryText)
                }
            }
        }
        if let icon = try sections.decodeIfPresent(FirstVersionIcon.self, forKey: .icon) {
            symbolColor = symbolColor ?? icon.color
        }
        if let folders = try sections.decodeIfPresent(FirstVersionFolders.self, forKey: .folders) {
            folderColorIntensity = folderColorIntensity ?? folders.intensity
            editDress { dress in
                dress.folders =
                    dress.folders
                    ?? CrestTheme.Dress.Folders(
                        color: folders.color, backColor: folders.backColor, outlineColor: folders.outlineColor,
                        highlightColor: folders.highlightColor, highlightOpacity: folders.highlightOpacity,
                        overrides: folders.overrides)
            }
        }
        if let palette = try sections.decodeIfPresent(FirstVersionPalette.self, forKey: .commandPalette) {
            editDress { dress in
                dress.commandPalette =
                    dress.commandPalette
                    ?? CrestTheme.Dress.CommandPalette(light: palette.light?.surface, dark: palette.dark?.surface)
            }
        }
        if let popovers = try sections.decodeIfPresent(FirstVersionPopovers.self, forKey: .popovers) {
            editDress { dress in
                dress.popovers =
                    dress.popovers
                    ?? CrestTheme.Dress.Popovers(
                        backgroundColor: popovers.background, textColor: popovers.text,
                        secondaryTextColor: popovers.secondaryText, accentColor: popovers.accent,
                        accentOpacity: popovers.accentOpacity, buttonColor: popovers.button,
                        buttonOutlineColor: popovers.buttonOutline)
            }
        }
        if let controls = try sections.decodeIfPresent(FirstVersionControls.self, forKey: .controls) {
            editDress { dress in
                dress.controls =
                    dress.controls
                    ?? CrestTheme.Dress.Controls(
                        fillColor: controls.fill, fillOpacity: controls.fillOpacity, textColor: controls.text,
                        secondaryTextColor: controls.secondaryText)
            }
        }
    }

    private mutating func editDress(_ change: (inout CrestTheme.Dress) -> Void) {
        var edited = dress ?? CrestTheme.Dress()
        change(&edited)
        dress = edited
    }
}
