import Foundation

extension BrowserCredentialSession {
    /// Fills `credential` into the first login form of the page's main
    /// document, for a saved login a person chose outside the page. Answers
    /// whether a form took it.
    func fillFirstLogin(_ credential: BrowserCredential, evaluate: MainFrameEvaluate) async throws -> Bool {
        guard isEnabled else { return false }
        let result = try await evaluate(
            "return globalThis.__crestCredentialBridge?.fillFirstLogin(username, password) === true;",
            ["username": credential.descriptor.username, "password": credential.password])
        return result as? Bool == true
    }
}
