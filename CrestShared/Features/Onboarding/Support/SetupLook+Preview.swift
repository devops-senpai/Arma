import SwiftUI

/// What a look shows of itself before any Space wears it: a new Space's look
/// in the look's own sidebar mode and icon style, as the core gives them to
/// the Spaces setup makes.
extension SetupLook {
    // MARK: - Variables

    /// The look on the look every preview starts from: the one a new Space
    /// wears, Arma's own house under Arma's crest.
    var previewBranding: SpaceBranding { applying(to: SpaceHouse.newSpaceLook) }

    /// The symbol a previewed Space wears, which an icon shows and a crest
    /// keeps for the places too small for it.
    var previewSymbol: String { "house.fill" }

    // MARK: - Actions - Looks

    /// `branding` in this look: the sidebar mode and icon style the core
    /// gives the look, keeping its colors, crest and texture.
    func applying(to branding: SpaceBranding) -> SpaceBranding {
        var look = branding
        look.themeMode = themeMode
        look.iconStyle = iconStyle
        return look.normalized()
    }
}
