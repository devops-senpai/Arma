import Foundation

extension CrestSymbol {
    // MARK: - Static Variables

    /// The figure a crest draws when it names none it can read, as the core
    /// reads it.
    static let fallback = CrestSymbol.mountain

    /// The figures the gallery offers, Arma's own birds first: the bird of
    /// its logo, then the crane.
    static let selectable: [CrestSymbol] = {
        let first: [CrestSymbol] = [.sparrow, .crane]
        return first + all.filter { $0.isOffered && !first.contains($0) }
    }()
}

extension SpaceHouse {
    // MARK: - Static Variables

    /// The houses the galleries offer, Arma's own first.
    static let offered: [SpaceHouse] = [.arma] + all.filter { $0 != .arma }

    /// The houses that bring an app icon of their own; Arma's is the app's
    /// own icon, which the picker offers first already.
    static let withAppIcons: [SpaceHouse] = all.filter { $0 != .arma }
}

extension SpaceBranding {
    /// This look under the crest a new Space wears, as the core dresses one:
    /// Arma's guidon, pale and bird in laurel, in Catppuccin Macchiato's
    /// colors.
    var wearingNewSpaceCrest: SpaceBranding {
        var look = self
        look.crest = SpaceHouse.arma.look.crest
        look.crest.startingPresetID = nil
        look.wearMacchiatoCrestColors()
        return look
    }

    /// Gives the crest Catppuccin Macchiato's colors as its own, a layer at a
    /// time: dark grey fields, a mauve band, a white emblem, a lavender
    /// border and a base-dark edge.
    mutating func wearMacchiatoCrestColors() {
        keepIdentityColors()
        crest.palette = ColorPalette(
            colors: [Tincture.armaGrey, .armaGrey, .macchiatoMauve, .macchiatoText, .macchiatoLavender, .macchiatoBase]
                .map(\.color))
    }
}

extension CrestBackplate {
    // MARK: - Static Variables

    /// The shapes the gallery offers: None, then the guidon of Arma's
    /// logo, then the rest.
    static let offered: [CrestBackplate] = [.none, .flag] + all.filter { $0 != .none && $0 != .flag }
}
