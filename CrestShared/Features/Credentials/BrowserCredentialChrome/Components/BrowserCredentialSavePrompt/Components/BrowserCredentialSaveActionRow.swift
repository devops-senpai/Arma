import SwiftUI

/// The row the save prompt's actions sit on: Never for This Site at the
/// leading edge, the commit at the trailing one, stacked once the text is
/// large enough that they would not fit beside each other.
struct BrowserCredentialSaveActionRow: View {
    let route: BrowserCredentialPromptRoute
    let space: BrowserSpaceIdentity?
    let metrics: BrowserCredentialPromptMetrics
    let dismiss: () -> Void
    /// Stops the Space offering to save on this site, while the prompt asks.
    var neverSave: (() -> Void)? = nil
    let perform: (BrowserCredentialPromptPrimaryAction) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: BrowserCredentialPromptMetrics.saveActionSpacing) {
                actions(isStacked: true)
                neverSaveAction
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            HStack {
                neverSaveAction
                Spacer(minLength: 0)
                actions(isStacked: false)
            }
        }
    }

    @ViewBuilder
    private var neverSaveAction: some View {
        if let neverSave {
            Button("Never for This Site", action: neverSave)
                .disabled(route.isBusy)
                .accessibilityIdentifier("crest-password-save-never")
        }
    }

    private func actions(isStacked: Bool) -> BrowserCredentialSaveActions {
        BrowserCredentialSaveActions(
            route: route,
            space: space,
            metrics: metrics,
            isStacked: isStacked,
            dismiss: dismiss,
            perform: perform
        )
    }
}
