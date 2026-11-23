import SwiftUI

/// Never for This Site: the save prompt's answer that stops the Space
/// offering to save on the page's site at all.
struct BrowserCredentialNeverSaveButton: View {
    let route: BrowserCredentialPromptRoute
    let neverSave: () -> Void

    var body: some View {
        Button("Never for This Site", action: neverSave)
            .disabled(route.isBusy)
            .accessibilityIdentifier("crest-password-save-never")
    }
}
