import Foundation

extension BrowserPage {
    /// Closes the credential prompt the person closed, keeps prompts away for
    /// a moment and offers to pause them on this tab.
    func snoozeCredentialPrompts() {
        credentialState.snooze()
    }

    /// The offer to pause password prompts on this tab, while it shows.
    var credentialPauseOffer: UUID? { credentialState.pauseOffer }

    func dismissCredentialPauseOffer() {
        credentialState.dismissPauseOffer()
    }

    /// Whether Arma's password prompts are paused on this page.
    var areCredentialPromptsPaused: Bool { credentialState.isPaused }

    /// When a timed pause of this page's password prompts ends.
    var credentialPromptsPausedUntil: Date? { credentialState.pausedUntil }

    func pauseCredentialPrompts(for length: BrowserCredentialPauseLength) {
        credentialState.pause(for: length)
    }

    func resumeCredentialPrompts() {
        credentialState.resume()
    }

    /// Fills `credential` into the first login form of the page, as a person
    /// chose it from outside the page, such as the command palette. Answers
    /// whether a form took it; never while the page keeps passwords off.
    func fillFirstLoginForm(_ credential: BrowserCredential) async -> Bool {
        guard isCredentialAccessEnabled, let evaluate = credentialMainFrameEvaluator else { return false }
        return (try? await credentialSession.fillFirstLogin(credential, evaluate: evaluate)) ?? false
    }

    var credentialMainFrameEvaluator: BrowserCredentialSession.MainFrameEvaluate? {
        guard let scripting = pageEngine.contentScripting else { return engineAdapter.credentialMainFrameEvaluator }
        return { body, arguments in
            try await scripting.callAsyncJavaScriptInMainFrame(body, arguments: arguments)
        }
    }
}
