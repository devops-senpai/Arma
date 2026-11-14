import SwiftUI

/// The passwords this Space already holds for the site asking for one. It
/// appears only once the vault answers with some, so a field on a site with no
/// saved password raises nothing.
///
/// Everything the prompt needs from the page arrives through
/// `BrowserCredentialFillPort`, everything about how big it is comes from
/// `BrowserCredentialPromptMetrics`, and the surface under it is the one thing
/// a shell dresses differently. So both shells share this prompt rather than a
/// resemblance.
struct BrowserCredentialSuggestionPrompt: View {
    let request: BrowserCredentialFillRequest
    let port: BrowserCredentialFillPort
    let browser: BrowserStore
    let metrics: BrowserCredentialPromptMetrics

    @State private var model = BrowserCredentialSuggestionModel()
    @State private var fillErrorMessage: String?

    var body: some View {
        Group {
            if model.hasSomethingToShow {
                surface
            } else {
                // Measured as nothing, so an anchored placement never shows it.
                Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            }
        }
        .task(id: request.id) {
            fillErrorMessage = nil
            await model.load(request, in: port.spaceID, using: browser)
            guard !Task.isCancelled, model.phase == .empty else { return }
            port.dismiss()
        }
        .onDisappear(perform: model.cancel)
    }

    private var surface: some View {
        BrowserCredentialPromptSurface(
            accessibilityLabel: Text("Arma password suggestions"),
            accessibilityIdentifier: "crest-password-suggestions",
            width: metrics.fillPromptWidth,
            metrics: metrics
        ) {
            BrowserCredentialSuggestionPromptContent(
                request: request,
                space: space,
                siteIconData: port.siteIconData,
                model: model,
                fillErrorMessage: fillErrorMessage,
                metrics: metrics,
                dismiss: port.close ?? port.dismiss,
                fill: fill
            )
        }
    }

    private var space: BrowserSpaceIdentity? {
        browser.spaceModel(port.spaceID)?.identity
    }

    private func fill(_ descriptor: CredentialDescriptor) {
        Task { @MainActor in
            do {
                guard
                    let credential = try await browser.credential(
                        id: descriptor.id,
                        in: port.spaceID
                    )
                else {
                    fillErrorMessage = "That password is no longer available."
                    return
                }
                try await port.fill(credential, request.id)
            } catch {
                fillErrorMessage = "The form changed before Arma could fill it."
            }
        }
    }
}
