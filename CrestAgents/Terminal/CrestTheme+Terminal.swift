import Foundation

// What `arma theme` does to a theme beyond reading and writing it: the parts
// of a look a reset names, and laying the choices of the command's options or
// of a second theme file over a saved theme.

// MARK: - Types

/// One part of a look that `arma theme reset` puts back.
enum CrestThemeSection: String, Codable, CaseIterable, Sendable {
    /// The banner, its texture and text tone, and the sidebar's text colors.
    case background
    /// The icon's color.
    case icon
    /// The folders' colors, intensity, highlight and single-folder colors.
    case folders
    case commandPalette = "command-palette"
    case popovers
    /// The address field and the pins.
    case controls
}

extension CrestTheme {
    // MARK: - Actions - Merging

    /// This theme with every member `other` names taking over, in the look and
    /// in the dark look alike.
    func merging(_ other: CrestTheme) -> CrestTheme {
        var merged = self
        if let name = other.name { merged.name = name }
        merged.look = look.merging(other.look)
        if let otherDark = other.dark { merged.dark = (dark ?? Look()).merging(otherDark) }
        if let darkLook = other.darkLook { merged.darkLook = darkLook }
        return merged
    }
}

extension CrestTheme.Look {
    // MARK: - Actions - Merging

    /// This look with every member `other` names taking over.
    func merging(_ other: CrestTheme.Look) -> CrestTheme.Look {
        var merged = self
        if let value = other.colors { merged.colors = value }
        if let value = other.themeMode { merged.themeMode = value }
        if let value = other.bannerPattern { merged.bannerPattern = value }
        if let value = other.gradientAngle { merged.gradientAngle = value }
        if let value = other.bannerStrength { merged.bannerStrength = value }
        if let value = other.readabilityFade { merged.readabilityFade = value }
        if let value = other.keepsControlsReadable { merged.keepsControlsReadable = value }
        if let value = other.textureStrength { merged.textureStrength = value }
        if let value = other.textColorMode { merged.textColorMode = value }
        if let value = other.iconStyle { merged.iconStyle = value }
        if let value = other.symbolColor { merged.symbolColor = value }
        if let value = other.folderColorIntensity { merged.folderColorIntensity = value }
        if let dress = other.dress { merged.dress = (merged.dress ?? CrestTheme.Dress()).merging(dress) }
        return merged
    }

    // MARK: - Actions - Resetting

    /// This look with the members of `section` as `plain` has them, the rest kept.
    func resetting(_ section: CrestThemeSection, to plain: CrestTheme.Look) -> CrestTheme.Look {
        var reset = self
        var dress = reset.dress ?? CrestTheme.Dress()
        switch section {
        case .background:
            reset.colors = plain.colors
            reset.themeMode = plain.themeMode
            reset.bannerPattern = plain.bannerPattern
            reset.gradientAngle = plain.gradientAngle
            reset.bannerStrength = plain.bannerStrength
            reset.readabilityFade = plain.readabilityFade
            reset.keepsControlsReadable = plain.keepsControlsReadable
            reset.textureStrength = plain.textureStrength
            reset.textColorMode = plain.textColorMode
            dress.text = plain.dress?.text
        case .icon:
            reset.symbolColor = plain.symbolColor
        case .folders:
            reset.folderColorIntensity = plain.folderColorIntensity
            dress.folders = plain.dress?.folders
            // An empty set of single-folder colors takes away the ones a theme had.
            if dress.folders?.overrides == nil { dress.folders?.overrides = [:] }
        case .commandPalette:
            dress.commandPalette = plain.dress?.commandPalette
        case .popovers:
            dress.popovers = plain.dress?.popovers
        case .controls:
            dress.controls = plain.dress?.controls
        }
        reset.dress = dress == CrestTheme.Dress() ? nil : dress
        return reset
    }
}

extension CrestTheme.Dress {
    // MARK: - Actions - Merging

    /// This dress with every member `other` names taking over.
    func merging(_ other: CrestTheme.Dress) -> CrestTheme.Dress {
        var merged = self
        if let text = other.text {
            var part = merged.text ?? Text()
            if let value = text.color { part.color = value }
            if let value = text.secondaryColor { part.secondaryColor = value }
            merged.text = part
        }
        if let folders = other.folders {
            var part = merged.folders ?? Folders()
            if let value = folders.color { part.color = value }
            if let value = folders.backColor { part.backColor = value }
            if let value = folders.outlineColor { part.outlineColor = value }
            if let value = folders.highlightColor { part.highlightColor = value }
            if let value = folders.highlightOpacity { part.highlightOpacity = value }
            if let value = folders.overrides { part.overrides = (part.overrides ?? [:]).merging(value) { $1 } }
            merged.folders = part
        }
        if let palette = other.commandPalette {
            var part = merged.commandPalette ?? CommandPalette()
            part.light = Self.merged(part.light, with: palette.light)
            part.dark = Self.merged(part.dark, with: palette.dark)
            merged.commandPalette = part
        }
        if let popovers = other.popovers {
            var part = merged.popovers ?? Popovers()
            if let value = popovers.backgroundColor { part.backgroundColor = value }
            if let value = popovers.textColor { part.textColor = value }
            if let value = popovers.secondaryTextColor { part.secondaryTextColor = value }
            if let value = popovers.accentColor { part.accentColor = value }
            if let value = popovers.accentOpacity { part.accentOpacity = value }
            if let value = popovers.buttonColor { part.buttonColor = value }
            if let value = popovers.buttonOutlineColor { part.buttonOutlineColor = value }
            merged.popovers = part
        }
        if let controls = other.controls {
            var part = merged.controls ?? Controls()
            if let value = controls.fillColor { part.fillColor = value }
            if let value = controls.fillOpacity { part.fillOpacity = value }
            if let value = controls.textColor { part.textColor = value }
            if let value = controls.secondaryTextColor { part.secondaryTextColor = value }
            merged.controls = part
        }
        return merged
    }

    private static func merged(_ surface: PaletteSurface?, with other: PaletteSurface?) -> PaletteSurface? {
        guard let other else { return surface }
        var merged = surface ?? PaletteSurface()
        if let value = other.tint { merged.tint = value }
        if let value = other.opacity { merged.opacity = value }
        if let value = other.textColor { merged.textColor = value }
        return merged
    }
}
