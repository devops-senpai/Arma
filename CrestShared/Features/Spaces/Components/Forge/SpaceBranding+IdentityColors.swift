import SwiftUI

extension EnvironmentValues {
    /// Whether a house chosen in the Crest Studio starts the Space's whole
    /// look over, as upstream's does, rather than giving it only its crest.
    /// A Space's Appearance page turns it on with Modify Theme Too.
    @Entry var browserHouseStartsLook = false
}

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
        var updated = self
        updated.iconStyle = .layeredCrest
        updated.crest = started.crest
        updated.hasCustomAppearance = true
        return updated.normalized()
    }

    /// Whether this look wears `house`'s crest as `wearingCrest(of:)` gives it.
    func wearsCrest(of house: SpaceHouse) -> Bool {
        iconStyle == .layeredCrest && crest == wearingCrest(of: house).crest
    }

    /// `house`'s whole look, crest included, in place of this one. Unlike
    /// `SpaceHouse.applying(to:)`, nothing of this look is kept: a house's
    /// look is drawn for the browser's own folder, command palette, popover
    /// and control colors, so whatever a theme set of those goes back to them.
    func startingOver(from house: SpaceHouse) -> SpaceBranding {
        var look = house.look
        look.iconStyle = .layeredCrest
        look.crest.startingPresetID = house.name
        look.hasCustomAppearance = false
        return look.normalized()
    }

    /// Whether this look is `house`'s whole look, as `startingOver(from:)` gives it.
    func startedOver(from house: SpaceHouse) -> Bool {
        normalized() == startingOver(from: house)
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
