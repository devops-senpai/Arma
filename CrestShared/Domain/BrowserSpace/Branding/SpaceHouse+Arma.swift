import Foundation

extension SpaceHouse {
    // MARK: - Static Variables

    /// The houses the galleries offer, Arma's own first.
    static let offered: [SpaceHouse] = [.arma] + all.filter { $0 != .arma }

    /// The houses that bring an app icon of their own; Arma's is the app's
    /// own icon, which the picker offers first already.
    static let withAppIcons: [SpaceHouse] = all.filter { $0 != .arma }

    /// The crest a new Space wears, as the core's `SpaceHouse.NewSpaceCrest`
    /// composes it: Arma's arms, the guidon with a gold pale and a red bird
    /// in a double gold line, embossed and lifted on Arma navy, in the
    /// crest's own colors so a theme never changes them. Setup draws it
    /// before the core has made a Space; the core's is the one a Space gets.
    static let newSpaceCrest = SpaceCrest(
        backplate: .flag, fieldDivision: .plain, ordinary: .pale, trim: .doubleLine, symbol: .sparrow,
        chargeLayout: .single, backplateColorIndex: 0, secondaryFieldColorIndex: 1, ordinaryColorIndex: 2,
        trimColorIndex: 4, symbolColorIndex: 3, startingPresetID: nil, edgeColorIndex: 5,
        palette: ColorPalette(colors: [
            BrandColor(red: 0.192, green: 0.196, blue: 0.267, alpha: 1),
            BrandColor(red: 0.812, green: 0.82, blue: 0.831, alpha: 1),
            BrandColor(red: 0.871, green: 0.729, blue: 0.318, alpha: 1),
            BrandColor(red: 0.749, green: 0.18, blue: 0.137, alpha: 1),
            BrandColor(red: 0.863, green: 0.758, blue: 0.359, alpha: 1),
            BrandColor(red: 0.255, green: 0.271, blue: 0.349, alpha: 1),
        ]),
        charge: nil, plateScale: 1, edgeWidth: 0.268, divisionCount: SpaceCrest.defaultDivisionCount,
        finish: .embossed, ordinaryWidth: 1.013, trimWeight: 0.827, trimDetail: SpaceCrest.defaultTrimDetail,
        chargeScale: 1.165, chargeOffset: 0, chargeWeight: .bold, sheenAngle: 45, sealTeeth: 18,
        showsOutline: false, depth: .lifted)

    /// The look a new Space wears, as the core's `SpaceHouse.NewSpaceLook`
    /// gives the first accent: Arma's own house under the new Space's crest.
    static let newSpaceLook: SpaceBranding = {
        var look = arma.look
        look.crest = newSpaceCrest
        return look.normalized()
    }()
}

extension CrestBackplate {
    // MARK: - Static Variables

    /// The shapes the galleries offer: None, then the guidon of Arma's logo,
    /// then the rest.
    static let offered: [CrestBackplate] = [.none, .flag] + all.filter { $0 != .none && $0 != .flag }
}
