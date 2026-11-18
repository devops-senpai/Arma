import SwiftUI

/// A Space's crest and icon colors kept apart from its sidebar's, so a theme
/// laid over the Space changes only the sidebar.
extension SpaceBranding {
    // MARK: - Actions - Identity

    /// Gives the crest and the icon colors of their own, the ones they wear
    /// now, so a theme's colors never change them: the crest a palette entry
    /// for each layer, and the icon its color rather than the accent.
    mutating func keepIdentityColors() {
        if symbolColor == nil { symbolColor = resolvedSymbolColor }
        guard !hasLayeredCrestPalette else { return }
        // As the Forge's first layer color does: each layer's entry copied
        // from what the layer wears now.
        let colors = crest.layerColors(spaceColors: self.colors)
        let worn = BrowserCrestForgeLayer.all.map { layer -> BrandColor in
            let index = crest[keyPath: layer.index]
            return colors.indices.contains(index) ? colors[index] : colors[0]
        }
        crest.palette = ColorPalette(colors: worn)
        for layer in BrowserCrestForgeLayer.all { crest[keyPath: layer.index] = layer.slot }
    }

    /// This look wearing a new crest shuffled from the Forge's parts, with
    /// the sidebar left as it is.
    func shuffledCrest() -> SpaceBranding {
        var shuffled = BrowserCrestForge.shuffled(self)
        shuffled.keepIdentityColors()
        var updated = self
        updated.crest = shuffled.crest
        updated.hasCustomAppearance = true
        return updated.normalized()
    }

    /// This look wearing `house`'s crest, its shape, emblem and border in
    /// the house's colors as the crest's own, with the sidebar left as it is.
    func wearingCrest(of house: SpaceHouse) -> SpaceBranding {
        var dressed = house.applying(to: self)
        dressed.keepIdentityColors()
        var updated = self
        updated.iconStyle = .layeredCrest
        updated.crest = dressed.crest
        updated.hasCustomAppearance = true
        return updated.normalized()
    }
}
