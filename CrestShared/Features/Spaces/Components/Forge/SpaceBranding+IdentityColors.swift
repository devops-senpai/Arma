import SwiftUI

/// A Space's crest and icon colors kept apart from its sidebar's, so a theme
/// laid over the Space changes only the sidebar.
extension SpaceBranding {
    // MARK: - Actions - Identity

    /// Gives the crest and the icon colors of their own, the ones they wear
    /// now, so a theme's colors never change them: the crest a palette entry
    /// for each layer, and the icon its color rather than the accent.
    mutating func keepIdentityColors() {
        if symbolColor == nil { symbolColor = primaryColor }
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

    /// This look wearing `house`'s crest in the house's own colors, with the
    /// sidebar left as it is. Upstream a house starts the whole look over,
    /// colors included; here the Space's theme colors the sidebar, so a
    /// house gives the Space only its crest.
    func wearingCrest(of house: SpaceHouse) -> SpaceBranding {
        var started = house.applying(to: self)
        started.keepIdentityColors()
        return wearing(started.crest)
    }

    /// This look wearing `crest` as its icon, with the sidebar left as it is.
    func wearing(_ crest: SpaceCrest) -> SpaceBranding {
        var updated = self
        updated.iconStyle = .layeredCrest
        updated.crest = crest
        updated.hasCustomAppearance = true
        return updated.normalized()
    }

    /// Whether this look wears `house`'s crest as `wearingCrest(of:)` gives it.
    func wearsCrest(of house: SpaceHouse) -> Bool {
        iconStyle == .layeredCrest && crest == wearingCrest(of: house).crest
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
}
