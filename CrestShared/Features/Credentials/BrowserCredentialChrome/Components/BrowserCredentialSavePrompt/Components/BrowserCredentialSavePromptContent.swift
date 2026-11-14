import SwiftUI

struct BrowserCredentialSavePromptContent: View {
    let candidate: BrowserCredentialSaveCandidate
    let route: BrowserCredentialPromptRoute
    let destination: BrowserCredentialPromptDestinationMetadata
    let space: BrowserSpaceIdentity?
    let namesSystemPasswordsDestination: Bool
    let metrics: BrowserCredentialPromptMetrics
    let dismiss: () -> Void
    /// Stops the Space offering to save on this site, while the prompt asks.
    var neverSave: (() -> Void)? = nil
    /// The account and password to correct before saving, while the prompt
    /// asks.
    var fields: BrowserCredentialSaveFields? = nil
    let perform: (BrowserCredentialPromptPrimaryAction) -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: BrowserCredentialPromptMetrics.savePromptContentSpacing
        ) {
            BrowserCredentialSavePromptHeader(
                candidate: candidate,
                route: route,
                space: space,
                metrics: metrics,
                showsAccount: fields == nil,
                dismiss: dismiss,
                perform: perform
            )

            if let fields {
                fields
            }

            BrowserCredentialSaveDestination(
                destination: destination,
                space: space,
                namesSystemPasswordsDestination: namesSystemPasswordsDestination
            )

            if candidate.isCrossOriginFrame {
                Text(
                    route.crossOriginMessage(
                        frameOrigin: candidate.origin,
                        topLevelOrigin: candidate.topLevelOrigin,
                        subject: metrics.saveCrossOriginSubject
                    )
                )
                .font(.caption)
                .foregroundStyle(CrestColor.warning)
            }

            if let errorMessage = route.errorMessage(spaceName: space?.name) {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(CrestColor.danger)
            }

            if metrics.saveActionPlacement == .belowContent {
                BrowserCredentialSaveActionRow(
                    route: route,
                    space: space,
                    metrics: metrics,
                    dismiss: dismiss,
                    neverSave: neverSave,
                    perform: perform
                )
            }
        }
    }
}
