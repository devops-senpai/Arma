import SwiftUI

/// The save prompt closes from the ✕ at its corner, and on its own after the
/// Space's time while it only asks: held while the pointer rests on it, and
/// never while a save runs or after something failed. Both answer as Not Now
/// does, so the address field's key still offers the password.
extension BrowserCredentialSavePrompt {
    /// What restarts the prompt's countdown: another candidate, the pointer
    /// arriving or leaving, or the prompt starting or stopping asking.
    struct Countdown: Hashable {
        let candidateID: UUID
        let isPointerResting: Bool
        let isAsking: Bool
    }

    var countdown: Countdown {
        Countdown(candidateID: candidate.id, isPointerResting: isPointerResting, isAsking: isAsking)
    }

    /// Whether the prompt only asks: whether to save or to update.
    var isAsking: Bool {
        model.phase == .create || model.phase == .update
    }

    /// The ✕ at the card's corner, set as a notification's is. The touch band
    /// has its own close in its header.
    @ViewBuilder
    var closeButton: some View {
        if metrics.surfaceStyle == .panel {
            Button(action: answerDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: BrowserCredentialPromptMetrics.closeGlyphSize, weight: .bold))
            }
            .buttonStyle(
                CrestChromeButtonStyle(
                    controlSize: CGSize(
                        width: BrowserCredentialPromptMetrics.closeButtonSize,
                        height: BrowserCredentialPromptMetrics.closeButtonSize),
                    cornerRadius: BrowserCredentialPromptMetrics.closeButtonSize / 2, showsRestingFill: true)
            )
            .offset(
                x: -BrowserCredentialPromptMetrics.closeButtonInset, y: -BrowserCredentialPromptMetrics.closeButtonInset
            )
            .disabled(model.isBusy)
            .help(Text("Close"))
            .accessibilityLabel(Text("Close"))
            .accessibilityIdentifier("crest-password-save-close")
        }
    }

    /// Puts the prompt away once the Space's time is up, counted from when it
    /// starts asking and again whenever the pointer leaves it.
    func closeWhenTimeIsUp() async {
        guard isAsking, !isPointerResting else { return }
        try? await Task.sleep(for: .seconds(preferences.savePromptSeconds))
        guard !Task.isCancelled, isAsking, !isPointerResting, port.presentedCandidateID() == candidate.id
        else { return }
        answerDismiss()
    }
}
