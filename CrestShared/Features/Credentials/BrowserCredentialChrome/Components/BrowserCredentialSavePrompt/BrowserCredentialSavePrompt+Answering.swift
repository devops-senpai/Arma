import SwiftUI

/// While the save prompt asks, the person can correct what it keeps and tell
/// the Space never to save on the site; it closes from the ✕ at its corner, or
/// on its own after the Space's time while it only asks, held while the pointer
/// rests on it and once the person starts answering.
extension BrowserCredentialSavePrompt {
    /// What restarts the prompt's countdown: another candidate, the pointer
    /// arriving or leaving, or the prompt starting or stopping asking.
    struct Countdown: Hashable {
        let candidateID: UUID
        let isPointerResting: Bool
        let closes: Bool
    }

    var countdown: Countdown {
        Countdown(candidateID: candidate.id, isPointerResting: isPointerResting, closes: model.closesOnItsOwn)
    }

    /// Never for This Site, offered only while the prompt asks.
    var neverSaveAction: (() -> Void)? {
        guard model.asksForAnswer else { return nil }
        return { neverSaveOnSite() }
    }

    /// The ✕ at the prompt's corner, which puts it away as Not Now does.
    var closeButton: some View {
        Button(action: port.dismiss) {
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
        .accessibilityLabel(Text("Close"))
        .accessibilityIdentifier("crest-password-save-close")
    }

    /// Puts the prompt away once its time is up, as long as it is only
    /// asking: the Space's time from when it starts asking, starting over
    /// whenever the pointer leaves it, since the pointer often crosses the
    /// corner it sits in. Never while the pointer rests on it, a save is
    /// under way or something failed.
    func closeWhenTimeIsUp() async {
        guard model.closesOnItsOwn, !isPointerResting else { return }
        try? await Task.sleep(for: .seconds(preferences.savePromptSeconds))
        guard !Task.isCancelled, model.closesOnItsOwn, !isPointerResting,
            port.presentedCandidateID() == candidate.id
        else { return }
        port.dismiss()
    }

    /// Stops this Space offering to save on the page's site and everything
    /// under it, then puts the prompt away. A site whose subdomains belong to
    /// others is kept alone. Saved passwords still fill there.
    func neverSaveOnSite() {
        let host = candidate.topLevelOrigin.host
        do {
            try browser.neverSaveSite(host, includesSubdomains: true, in: port.spaceID)
        } catch {
            try? browser.neverSaveSite(host, includesSubdomains: false, in: port.spaceID)
        }
        port.dismiss()
    }
}
