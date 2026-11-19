import XCTest

@testable import Crest

/// A theme file reads in both versions into the same look, and dresses a
/// Space's branding with what it names.
final class CrestThemeFileTests: XCTestCase {
    // MARK: - Actions - Reading

    /// A file written before version 2 named its members by section, with a
    /// texture that was on or off; it reads as the same look, the texture at
    /// full strength or none, and is written back as version 2.
    func testAFirstVersionFileReadsAsTheSameLook() throws {
        let file = Data(
            """
            {"name": "Dusk",
             "background": {"colors": ["#1b1f2a", "#3a2f5b"], "style": "gradient", "angle": 135, "intensity": 0.8,
                            "texture": true, "textColor": "light", "sidebarText": "#e6e9ef"},
             "icon": {"color": "#ffd166"},
             "folders": {"color": "#7a8bb0", "outlineColor": "default", "intensity": 0.3},
             "commandPalette": {"dark": {"tint": "#101218", "opacity": 0.7, "text": "#cdd6f4"}},
             "popovers": {"background": "#0b2733", "accentOpacity": 0.5},
             "controls": {"fill": "#12394a", "fillOpacity": 0.9},
             "dark": {"background": {"texture": false}}}
            """.utf8)

        let theme = try CrestTheme(json: file)

        XCTAssertEqual(theme.name, "Dusk")
        XCTAssertEqual(theme.look.colors, ["#1b1f2a", "#3a2f5b"])
        XCTAssertEqual(theme.look.themeMode, "gradient")
        XCTAssertEqual(theme.look.gradientAngle, 135)
        XCTAssertEqual(theme.look.bannerStrength, 0.8)
        XCTAssertEqual(theme.look.textureStrength, 1)
        XCTAssertEqual(theme.dark?.textureStrength, 0)
        XCTAssertEqual(theme.look.folderColorIntensity, 0.3)
        XCTAssertEqual(theme.look.dress?.text?.color, "#e6e9ef")
        XCTAssertEqual(theme.look.dress?.folders?.outlineColor, "default")
        XCTAssertEqual(theme.look.dress?.commandPalette?.dark?.textColor, "#cdd6f4")
        XCTAssertEqual(theme.look.dress?.popovers?.backgroundColor, "#0b2733")
        XCTAssertEqual(theme.look.dress?.controls?.fillOpacity, 0.9)

        let written = try theme.json()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: written) as? [String: Any])
        XCTAssertEqual(object["version"] as? Int, 2)
        XCTAssertNil(object["background"])
        XCTAssertEqual(try CrestTheme(json: written), theme)
    }

    /// A theme dresses a look with what it names and keeps the rest.
    func testAThemeDressesOnlyWhatItNames() throws {
        let theme = try CrestTheme(
            json: Data(
                """
                {"version": 2, "textureStrength": 0.4,
                 "dress": {"folders": {"color": "#04a5e5", "highlightOpacity": 0.34}}}
                """.utf8))
        let start = SpaceHouse.lion.look

        let dressed = try start.dressed(in: theme)

        XCTAssertEqual(dressed.textureStrength, 0.4)
        XCTAssertEqual(dressed.folderColor, BrandColor(hex: "#04a5e5"))
        XCTAssertEqual(dressed.folderHighlightOpacity, 0.34)
        XCTAssertEqual(dressed.colors, start.colors)
        XCTAssertEqual(dressed.crest, start.crest)
        XCTAssertEqual(dressed.hasCustomAppearance, true)
    }
}
