import Foundation

extension SpaceHouse {
    // MARK: - Static Variables

    /// The houses the galleries offer, Arma's own first.
    static let offered: [SpaceHouse] = [.arma] + all.filter { $0 != .arma }

    /// The houses that bring an app icon of their own; Arma's is the app's
    /// own icon, which the picker offers first already.
    static let withAppIcons: [SpaceHouse] = all.filter { $0 != .arma }
}

extension CrestBackplate {
    // MARK: - Static Variables

    /// The shapes the galleries offer: None, then the guidon of Arma's logo,
    /// then the rest.
    static let offered: [CrestBackplate] = [.none, .flag] + all.filter { $0 != .none && $0 != .flag }
}
