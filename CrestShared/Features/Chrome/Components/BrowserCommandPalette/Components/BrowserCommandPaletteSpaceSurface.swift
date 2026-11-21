import SwiftUI

/// The tint the Space's command palette look lays between the system material
/// and the card's contents for the appearance the card shows in, so the
/// material never washes it out. It keeps the card's shape so the glass keeps
/// its own edge.
struct BrowserCommandPaletteSpaceTint: View {
    let shape: RoundedRectangle
    let space: SpaceModel?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let surface = space?.paletteSurface(dark: colorScheme == .dark), let color = surface.tint,
            surface.opacity > 0
        {
            shape.fill(color.color.opacity(surface.opacity))
        }
    }
}

/// The palette's contents in the text color the Space chose for this
/// appearance, when it chose one, and in the scheme that text reads in, so
/// the query field, its placeholder and the secondary text read on a dark
/// surface in a light window too. The surface goes down to the rows, whose
/// selected one reads its own text color from it.
struct BrowserCommandPaletteSpaceText: ViewModifier {
    let space: SpaceModel?

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let surface = space?.paletteSurface(dark: colorScheme == .dark)
        return content.modifier(SpaceTextColor(color: surface?.textColor))
            .environment(\.colorScheme, surface?.foregroundTone?.colorScheme ?? colorScheme)
            .environment(\.browserCommandPaletteSurface, surface)
    }
}

extension EnvironmentValues {
    /// The palette surface the card wears in the appearance it shows in, or
    /// nil where the Space leaves the card to the system material.
    @Entry var browserCommandPaletteSurface: SpacePaletteSurface? = nil
}

extension SpaceModel {
    // MARK: - Actions - Command Palette

    /// The Space's palette surface for the appearance `dark` names, or nil
    /// where the Space leaves the card to the system material.
    @MainActor
    func paletteSurface(dark: Bool) -> SpacePaletteSurface? {
        settings.shownLook.commandPalette?.surface(dark: dark)
    }
}
