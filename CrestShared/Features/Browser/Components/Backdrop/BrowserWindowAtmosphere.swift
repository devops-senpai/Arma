import SwiftUI

struct BrowserWindowAtmosphere: View {
    // MARK: - Variables

    /// The Space the window shows, or nil for none.
    let space: SpaceModel?

    @Environment(\.colorScheme) private var colorScheme

    /// The Space's look as the current appearance shows it, read in `body`
    /// so it follows the appearance and Space-colors preferences.
    private var branding: SpaceBranding? {
        space.map(\.settings.shownLook.shown)
    }

    var body: some View {
        ZStack {
            CrestColor.windowBackground
            if let branding {
                // The field shows through to the window background by its
                // intensity, and that color is dark in a dark window, so a
                // light look went grey there. Drawn in the scheme the look
                // reads in, the base under it is light under a light look
                // and dark under a dark one, whatever the window is.
                BrowserSpaceBackdropLayer(spaceID: space?.id, branding: branding)
                    .environment(\.colorScheme, branding.colorScheme(over: colorScheme))
            }
        }
        .accessibilityHidden(true)
    }
}
