import SwiftUI

/// How often a Space asks the person to authenticate before it shows or
/// copies a saved password. Changing it asks the person to authenticate
/// first, whatever it is set to, so the choice can't be used to get around
/// itself; cancelling leaves it as it was.
struct BrowserCredentialAuthenticationRow: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    /// Whether a change waits for the person to authenticate.
    @State private var isAuthorizing = false

    private var choice: Binding<CredentialAuthentication> {
        let stored = browser.credentialPreferenceBinding(\.authentication, in: space)
        return Binding(
            get: { stored.wrappedValue },
            set: { chosen in
                guard chosen != stored.wrappedValue, !isAuthorizing else { return }
                isAuthorizing = true
                Task { @MainActor in
                    defer { isAuthorizing = false }
                    let access = BrowserCredentialSensitiveAccess(browser: browser)
                    guard (try? await access.authorizeAuthenticationChange(in: space.id)) != nil else { return }
                    stored.wrappedValue = chosen
                }
            })
    }

    // MARK: - Actions - Drawing

    var body: some View {
        Picker("Ask to authenticate", selection: choice) {
            ForEach(CredentialAuthentication.all, id: \.self) { option in
                Text(option.title).tag(option)
            }
        }
        .disabled(isAuthorizing)
        .accessibilityIdentifier("space-credential-authentication")
    }
}
