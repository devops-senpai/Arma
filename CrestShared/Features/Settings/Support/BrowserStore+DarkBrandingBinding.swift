import SwiftUI

extension BrowserStore {
    // MARK: - Actions - Bindings

    /// The look a Space wears while windows are dark, edited as a whole value.
    /// Reads the light look while the Space has no dark one of its own.
    func spaceDarkBrandingBinding(in space: SpaceModel) -> Binding<SpaceBranding> {
        Binding {
            space.settings.darkLook
        } set: { [self] branding in
            updateSpaceDarkBranding(branding, in: space.id)
        }
    }
}
