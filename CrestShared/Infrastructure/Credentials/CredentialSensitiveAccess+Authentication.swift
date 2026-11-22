import Foundation

extension BrowserCredentialSensitiveAccess {
    /// Asks the person to authenticate before one password of Space
    /// `spaceID` is shown or copied, unless the Space's choice lets it through
    /// without: it never asks, or the person authenticated for it recently
    /// enough. Reading or exporting every password of a Space asks the
    /// authenticator itself, always.
    func authenticate(for spaceID: UUID, reason: String) async throws {
        let memory = browser.family.credentialAuthenticationMemory
        let choice = browser.spaceModel(spaceID)?.settings.credentialPreferences.authentication ?? .eachTime
        let check = CredentialAuthenticationCheck(
            authentication: choice, secondsSinceLastAuthenticated: memory.secondsSinceAuthenticated(in: spaceID))
        guard (try? browser.core.query(check))?.asks ?? true else { return }
        guard try await authenticator.authenticate(reason: reason) else {
            throw BrowserCredentialSensitiveAccessError.authenticationDenied
        }
        memory.authenticated(in: spaceID)
    }

    /// Asks the person to authenticate before Space `spaceID` changes how
    /// often it asks, always, whatever it is set to now, so the setting can't
    /// be lowered to get around it. Throws when they don't.
    func authorizeAuthenticationChange(in spaceID: UUID) async throws {
        let reason = String(localized: "Authenticate to change when Arma asks before showing passwords.")
        guard try await authenticator.authenticate(reason: reason) else {
            throw BrowserCredentialSensitiveAccessError.authenticationDenied
        }
        browser.family.credentialAuthenticationMemory.authenticated(in: spaceID)
    }

    /// Asks the person to authenticate before Space `spaceID` lets the
    /// terminal reach its passwords, always. Throws when they don't.
    func authorizeCommandLineAccess(in spaceID: UUID) async throws {
        let reason = String(localized: "Authenticate to let the terminal reach these passwords.")
        guard try await authenticator.authenticate(reason: reason) else {
            throw BrowserCredentialSensitiveAccessError.authenticationDenied
        }
        browser.family.credentialAuthenticationMemory.authenticated(in: spaceID)
    }
}
