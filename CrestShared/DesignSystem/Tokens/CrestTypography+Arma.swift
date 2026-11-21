import SwiftUI

/// Arma's lettering: Pirata One, a textura blackletter, for Arma's name and a
/// page's title where they stand as a sign, and Times under them and for
/// the Start Page's title. Pirata One ships inside the app
/// under the SIL Open Font License beside Allo and is registered for this
/// process the first time it is asked for; should it ever be missing, the
/// system's serif stands in, bold.
extension CrestTypography {
    // MARK: - Static Variables

    private static let letteringRegistration = CrestDisplayFaceRegistration()

    // MARK: - Actions - Fonts

    /// Arma's name lettered in blackletter, at `size`.
    static func lettering(_ size: CGFloat) -> Font {
        guard letteringRegistration.isRegistered(.pirataOne) else {
            return .system(size: size, weight: .bold, design: .serif)
        }
        return .custom(CrestDisplayFace.pirataOne.postScriptName, fixedSize: size)
    }

    /// A line of Times, at `size`.
    static func serif(_ size: CGFloat) -> Font {
        .custom("Times New Roman", fixedSize: size)
    }
}

extension CrestDisplayFace {
    /// Pirata One, a static face: it has no axes, so its roundness and
    /// optical sizes are never asked for.
    static let pirataOne = CrestDisplayFace(
        fileName: "PirataOne-Regular", postScriptName: "PirataOne-Regular", roundness: 0, opticalSizes: 0...0)
}
