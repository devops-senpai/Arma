import Foundation

extension BrowserPage {
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
