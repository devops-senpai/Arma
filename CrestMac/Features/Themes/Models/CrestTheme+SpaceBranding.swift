import Foundation

/// A theme read from a Space's looks, and laid onto them: the one place a
/// theme file's members and a Space's branding are translated.
extension CrestTheme {
    // MARK: - Initializers

    /// Everything `look` chooses, and the same of `dark` when the Space has
    /// a look of its own for dark windows.
    init(look: SpaceBranding, dark: SpaceBranding? = nil) {
        self.init(look: Look(look), dark: dark.map(Look.init))
    }

    // MARK: - Actions - Colors

    /// `color` as a theme spells it.
    static func text(_ color: BrandColor) -> String {
        color.hexText
    }

    /// `color` as a theme spells it, or the word that lets a color go.
    static func text(_ color: BrandColor?) -> String {
        color.map(text) ?? defaultColorWord
    }

    /// The color `text` spells, nil for the word `default`, or a problem for
    /// anything else.
    static func color(_ text: String) throws(CrestThemeProblem) -> BrandColor? {
        if text == defaultColorWord { return nil }
        guard let color = BrandColor(hex: text) else { throw .badColor(text) }
        return color
    }
}

extension CrestTheme.Look {
    // MARK: - Initializers

    /// Everything `look` chooses that a theme carries.
    init(_ look: SpaceBranding) {
        let folders = look.dress?.folders
        let palette = look.dress?.commandPalette
        let popovers = look.dress?.popovers
        let controls = look.dress?.controls
        self.init(
            colors: look.colors.colors.map(CrestTheme.text), themeMode: look.themeMode.name,
            bannerPattern: look.bannerPattern.name, gradientAngle: look.gradientAngle,
            bannerStrength: look.bannerStrength, readabilityFade: look.readabilityFade,
            keepsControlsReadable: look.keepsControlsReadable, textureStrength: look.textureStrength,
            textColorMode: look.textColorMode.name, iconStyle: look.iconStyle.name,
            symbolColor: CrestTheme.text(look.symbolColor), folderColorIntensity: look.folderColorIntensity,
            dress: CrestTheme.Dress(
                text: .init(
                    color: CrestTheme.text(look.sidebarTextColor),
                    secondaryColor: CrestTheme.text(look.sidebarSecondaryTextColor)),
                folders: .init(
                    color: CrestTheme.text(folders?.color), backColor: CrestTheme.text(folders?.backColor),
                    outlineColor: CrestTheme.text(folders?.outlineColor),
                    highlightColor: CrestTheme.text(folders?.highlightColor),
                    highlightOpacity: folders?.highlightOpacity,
                    overrides: folders?.overrides.map { overrides in
                        Dictionary(
                            overrides.overrides.map { entry in
                                (
                                    entry.path,
                                    CrestTheme.Dress.Folders.Override(
                                        color: entry.color.map(CrestTheme.text),
                                        backColor: entry.backColor.map(CrestTheme.text),
                                        outlineColor: entry.outlineColor.map(CrestTheme.text))
                                )
                            }, uniquingKeysWith: { first, _ in first })
                    }),
                commandPalette: .init(light: Self.surface(palette?.light), dark: Self.surface(palette?.dark)),
                popovers: .init(
                    backgroundColor: CrestTheme.text(popovers?.backgroundColor),
                    textColor: CrestTheme.text(popovers?.textColor),
                    secondaryTextColor: CrestTheme.text(popovers?.secondaryTextColor),
                    accentColor: CrestTheme.text(popovers?.accentColor), accentOpacity: popovers?.accentOpacity ?? 1,
                    buttonColor: CrestTheme.text(popovers?.buttonColor),
                    buttonOutlineColor: CrestTheme.text(popovers?.buttonOutlineColor)),
                controls: .init(
                    fillColor: CrestTheme.text(controls?.fillColor), fillOpacity: controls?.fillOpacity ?? 1,
                    textColor: CrestTheme.text(controls?.textColor),
                    secondaryTextColor: CrestTheme.text(controls?.secondaryTextColor))))
    }

    private static func surface(_ surface: SpacePaletteSurface?) -> CrestTheme.Dress.PaletteSurface {
        CrestTheme.Dress.PaletteSurface(
            tint: CrestTheme.text(surface?.tint), opacity: surface?.opacity ?? 0,
            textColor: CrestTheme.text(surface?.textColor),
            selectedTextColor: CrestTheme.text(surface?.selectedTextColor))
    }
}

extension SpaceBranding {
    // MARK: - Actions - Themes

    /// This look dressed in everything `theme`'s look names, the rest kept.
    /// Throws a problem for a word or color the theme misspells, changing
    /// nothing.
    func dressed(in theme: CrestTheme) throws(CrestThemeProblem) -> SpaceBranding {
        try dressed(in: theme.look)
    }

    /// This look and `dark`, the Space's look for dark windows, dressed in
    /// `theme`: the look dresses this look, and a worn dark look dresses the
    /// dark one, started from the dressed look when the Space had none.
    func dressed(in theme: CrestTheme, dark: SpaceBranding?) throws(CrestThemeProblem)
        -> (look: SpaceBranding, dark: SpaceBranding?)
    {
        let look = try dressed(in: theme)
        guard let darkLook = theme.wornDark else { return (look, dark) }
        return (look, try (dark ?? look).dressed(in: darkLook))
    }

    /// This look dressed in everything `theme` names, the rest kept.
    func dressed(in theme: CrestTheme.Look) throws(CrestThemeProblem) -> SpaceBranding {
        var look = self
        if let colors = theme.colors {
            var parsed: [BrandColor] = []
            for text in colors {
                guard let color = try CrestTheme.color(text) else { throw .badColor(text) }
                parsed.append(color)
            }
            look.colors = ColorPalette(colors: parsed)
            // A theme names each well as one color, so the wells stop running
            // on into the gradients a house gave them, as setting a well does.
            look.colorGradients = nil
        }
        if let name = theme.themeMode {
            guard let mode = SpaceThemeMode.named(name) else { throw .unknownStyle(name) }
            look.themeMode = mode
        }
        if let name = theme.bannerPattern {
            guard let pattern = SpaceBannerPattern.named(name) else { throw .unknownPattern(name) }
            look.bannerPattern = pattern
        }
        if let angle = theme.gradientAngle { look.gradientAngle = angle }
        if let strength = theme.bannerStrength { look.bannerStrength = strength }
        if let fade = theme.readabilityFade { look.readabilityFade = fade }
        if let keeps = theme.keepsControlsReadable { look.keepsControlsReadable = keeps }
        if let texture = theme.textureStrength { look.textureStrength = texture }
        if let name = theme.textColorMode {
            guard let mode = SpaceTextColorMode.named(name) else { throw .unknownTextColor(name) }
            look.textColorMode = mode
        }
        if let name = theme.iconStyle, let style = SpaceIconStyle.named(name) { look.iconStyle = style }
        if let text = theme.symbolColor { look.symbolColor = try CrestTheme.color(text) }
        if let intensity = theme.folderColorIntensity { look.folderColorIntensity = intensity }
        if let dress = theme.dress { try look.dress(in: dress) }
        if look != self { look.hasCustomAppearance = true }
        return look
    }

    // MARK: - Mutators

    private mutating func dress(in dress: CrestTheme.Dress) throws(CrestThemeProblem) {
        if let text = dress.text {
            if let color = text.color { sidebarTextColor = try CrestTheme.color(color) }
            if let color = text.secondaryColor { sidebarSecondaryTextColor = try CrestTheme.color(color) }
        }
        if let folders = dress.folders {
            if let color = folders.color { folderColor = try CrestTheme.color(color) }
            if let color = folders.backColor { folderBackColor = try CrestTheme.color(color) }
            if let color = folders.outlineColor { folderOutlineColor = try CrestTheme.color(color) }
            if let color = folders.highlightColor { folderHighlightColor = try CrestTheme.color(color) }
            if let opacity = folders.highlightOpacity { folderHighlightOpacity = opacity }
            if let overrides = folders.overrides {
                var entries: [FolderColorOverride] = []
                for (path, colors) in overrides.sorted(by: { $0.key < $1.key }) {
                    entries.append(
                        FolderColorOverride(
                            path: path, color: try colors.color.flatMap(CrestTheme.color),
                            backColor: try colors.backColor.flatMap(CrestTheme.color),
                            outlineColor: try colors.outlineColor.flatMap(CrestTheme.color)))
                }
                folderOverrides = entries.isEmpty ? nil : FolderColorOverrides(overrides: entries)
            }
        }
        if let palette = dress.commandPalette {
            try dressSurface(in: palette.light, dark: false)
            try dressSurface(in: palette.dark, dark: true)
        }
        if let popovers = dress.popovers {
            if let color = popovers.backgroundColor { popoverBackgroundColor = try CrestTheme.color(color) }
            if let color = popovers.textColor { popoverTextColor = try CrestTheme.color(color) }
            if let color = popovers.secondaryTextColor { popoverSecondaryTextColor = try CrestTheme.color(color) }
            if let color = popovers.accentColor { popoverAccentColor = try CrestTheme.color(color) }
            if let opacity = popovers.accentOpacity { popoverAccentOpacity = opacity }
            if let color = popovers.buttonColor { popoverButtonColor = try CrestTheme.color(color) }
            if let color = popovers.buttonOutlineColor { popoverButtonOutlineColor = try CrestTheme.color(color) }
        }
        if let controls = dress.controls {
            if let color = controls.fillColor { controlsFillColor = try CrestTheme.color(color) }
            if let opacity = controls.fillOpacity { controlsFillOpacity = opacity }
            if let color = controls.textColor { controlsTextColor = try CrestTheme.color(color) }
            if let color = controls.secondaryTextColor { controlsSecondaryTextColor = try CrestTheme.color(color) }
        }
    }

    private mutating func dressSurface(in surface: CrestTheme.Dress.PaletteSurface?, dark: Bool)
        throws(CrestThemeProblem)
    {
        guard let surface else { return }
        try editPaletteSurface(dark: dark) { (current) throws(CrestThemeProblem) in
            if let text = surface.tint { current = current.tinted(try CrestTheme.color(text)) }
            if let opacity = surface.opacity { current.opacity = opacity }
            if let text = surface.textColor { current.textColor = try CrestTheme.color(text) }
            if let text = surface.selectedTextColor { current.selectedTextColor = try CrestTheme.color(text) }
        }
    }
}

extension CrestTheme.Crest {
    // MARK: - Initializers

    /// `crest` as `look` wears it, kept under `name`: every part and
    /// measure, and each layer's color as the crest's own.
    init(name: String, crest: SpaceCrest, in look: SpaceBranding) {
        let worn = look.wearing(crest)
        let colors = Dictionary(
            uniqueKeysWithValues: zip(Self.layerWords, BrowserCrestForgeLayer.all).map { word, layer in
                (word, CrestTheme.text(worn.forgeFill(of: layer).colors[0]))
            })
        self.init(
            name: name, shape: crest.backplate.name, field: crest.fieldDivision.name, band: crest.ordinary.name,
            emblem: crest.symbol.name, border: crest.trim.name, finish: crest.finish.name, colors: colors,
            chargeLayout: crest.chargeLayout.name,
            charge: crest.charge.map { charge in
                Charge(kind: charge.kind.name, symbol: charge.symbol?.name, text: charge.text, style: charge.style?.name)
            },
            chargeWeight: crest.chargeWeight.name, plateScale: crest.plateScale, edgeWidth: crest.edgeWidth,
            divisionCount: crest.divisionCount, ordinaryWidth: crest.ordinaryWidth, trimWeight: crest.trimWeight,
            trimDetail: crest.trimDetail, chargeScale: crest.chargeScale, chargeOffset: crest.chargeOffset,
            sheenAngle: crest.sheenAngle, sealTeeth: crest.sealTeeth, showsOutline: crest.showsOutline,
            startedFrom: crest.startingPresetID)
    }

    // MARK: - Actions - Wearing

    /// The crest as `look` would wear it: `look`'s crest with every part,
    /// measure and color this names, each color the crest's own; a measure
    /// left out keeps `look`'s. Throws a problem for a word or color the
    /// theme misspells.
    func crest(on look: SpaceBranding) throws(CrestThemeProblem) -> SpaceCrest {
        var worn = look
        worn.iconStyle = .layeredCrest
        worn.crest.backplate = try Self.part(shape, CrestBackplate.all, \.name, "shape")
        worn.crest.fieldDivision = try Self.part(field, CrestFieldDivision.all, \.name, "field")
        worn.crest.ordinary = try Self.part(band, CrestOrdinary.all, \.name, "band")
        worn.crest.symbol = try Self.part(emblem, CrestSymbol.all, \.name, "emblem")
        worn.crest.trim = try Self.part(border, CrestTrim.all, \.name, "border")
        worn.crest.finish = try Self.part(finish, CrestFinish.all, \.name, "finish")
        if let chargeLayout {
            worn.crest.chargeLayout = try Self.part(chargeLayout, CrestChargeLayout.all, \.name, "charge layout")
        }
        if let charge {
            var symbol: CrestSymbol?
            if let word = charge.symbol { symbol = try Self.part(word, CrestSymbol.all, \.name, "charge symbol") }
            var style: CrestMonogramStyle?
            if let word = charge.style { style = try Self.part(word, CrestMonogramStyle.all, \.name, "monogram style") }
            worn.crest.charge = CrestCharge(
                kind: try Self.part(charge.kind, CrestChargeKind.all, \.name, "charge"), symbol: symbol,
                text: charge.text, style: style)
        } else {
            worn.crest.charge = nil
        }
        if let chargeWeight {
            worn.crest.chargeWeight = try Self.part(chargeWeight, CrestChargeWeight.all, \.name, "charge weight")
        }
        if let plateScale { worn.crest.plateScale = plateScale }
        if let edgeWidth { worn.crest.edgeWidth = edgeWidth }
        if let divisionCount { worn.crest.divisionCount = divisionCount }
        if let ordinaryWidth { worn.crest.ordinaryWidth = ordinaryWidth }
        if let trimWeight { worn.crest.trimWeight = trimWeight }
        if let trimDetail { worn.crest.trimDetail = trimDetail }
        if let chargeScale { worn.crest.chargeScale = chargeScale }
        if let chargeOffset { worn.crest.chargeOffset = chargeOffset }
        if let sheenAngle { worn.crest.sheenAngle = sheenAngle }
        if let sealTeeth { worn.crest.sealTeeth = sealTeeth }
        if let showsOutline { worn.crest.showsOutline = showsOutline }
        worn.crest.startingPresetID = startedFrom
        for (word, layer) in zip(Self.layerWords, BrowserCrestForgeLayer.all) {
            guard let text = colors[word], let color = try CrestTheme.color(text) else { continue }
            worn.setForgeColor(color, of: layer)
        }
        return worn.normalized().crest
    }

    /// The one of `all` named `word`, in any case, or a problem naming `part`.
    private static func part<Value>(
        _ word: String, _ all: [Value], _ name: KeyPath<Value, String>, _ part: String
    ) throws(CrestThemeProblem) -> Value {
        if let value = all.first(where: { $0[keyPath: name].caseInsensitiveCompare(word) == .orderedSame }) {
            return value
        }
        throw .unknownCrestPart(part, word, all.map { $0[keyPath: name] })
    }
}
