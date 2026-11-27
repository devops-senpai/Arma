import Foundation
import Observation

/// The look new Spaces on this device wear in place of the one their template
/// gives them: the theme a person chose for new Spaces under Appearance, or
/// none. A shell with a theme library keeps it; one without leaves it empty,
/// and its new Spaces wear the template's look as ever.
@MainActor
@Observable
final class BrowserDefaultSpaceLook {
    // MARK: - Static Variables

    static let shared = BrowserDefaultSpaceLook()

    // MARK: - Variables

    /// The look a new Space wears, and the one it wears in dark windows, or
    /// nil for the template's.
    var look: SpaceBranding?
    var darkLook: SpaceBranding?
    /// Notes that a Space was made wearing the look, so the shell can keep
    /// it wearing the theme.
    @ObservationIgnored var spaceMade: (@MainActor (UUID) -> Void)?
}
