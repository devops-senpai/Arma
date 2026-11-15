import SwiftUI

/// The offer to invent a password for the form asking for a new one.
///
/// Everything the prompt needs from the page arrives through
/// `BrowserCredentialFillPort`, everything about how big it is comes from
/// `BrowserCredentialPromptMetrics`, and the surface under it is the one thing
/// a shell dresses differently. So both shells share this prompt rather than a
/// resemblance.
struct BrowserStrongPasswordPrompt: View {
    let request: BrowserCredentialFillRequest
    let port: BrowserCredentialFillPort
    let browser: BrowserStore
    let metrics: BrowserCredentialPromptMetrics

    @State private var model = BrowserStrongPasswordOperationModel()
    /// The generator's options for this password, from the Space's own.
    @State private var generation: PasswordGeneration?

    var body: some View {
        BrowserCredentialPromptSurface(
            accessibilityLabel: Text("Strong password for \(spaceName)"),
            accessibilityIdentifier: "crest-strong-password",
            width: metrics.fillPromptWidth,
            metrics: metrics
        ) {
            BrowserStrongPasswordPromptContent(
                request: request,
                space: space,
                siteIconData: port.siteIconData,
                model: model,
                metrics: metrics,
                dismiss: port.close ?? port.dismiss,
                generation: Binding(
                    get: { generation ?? spaceGeneration },
                    set: { generation = $0 }),
                generateAndFill: generateAndFill
            )
        }
    }

    private var spaceGeneration: PasswordGeneration {
        browser.spaceModel(port.spaceID)?.settings.credentialPreferences.generation ?? .standard
    }

    private var space: BrowserSpaceIdentity? {
        browser.spaceModel(port.spaceID)?.identity
    }

    private var spaceName: String {
        space?.name ?? "this Space"
    }

    private func generateAndFill() {
        Task { @MainActor in
            await model.generateSaveAndFill(
                generate: {
                    try BrowserStrongPasswordGenerator.generate(
                        from: browser.strongPasswordRecipe(generation ?? spaceGeneration))
                },
                save: { password in
                    let candidate = BrowserCredentialSaveCandidate(
                        id: UUID(),
                        origin: request.origin,
                        topLevelOrigin: request.topLevelOrigin,
                        username: request.usernameHint ?? "",
                        password: password,
                        passwordKind: .new,
                        isCrossOriginFrame: request.isCrossOriginFrame,
                        submittedAt: request.requestedAt
                    )
                    _ = try await browser.commitCredentialSave(
                        candidate,
                        in: port.spaceID
                    )
                },
                fill: { password in
                    try await port.fillGeneratedPassword(password, request.id)
                }
            )
        }
    }
}
