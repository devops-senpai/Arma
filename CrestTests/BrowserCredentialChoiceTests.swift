import Foundation
import XCTest

@testable import Crest

/// The password choices a Space makes that guard its passwords: who may change
/// how often showing one asks, what a private window may suggest and save, and
/// what a terminal session key opens.
@MainActor
final class BrowserCredentialChoiceTests: XCTestCase {
    /// Changing how often a Space asks to authenticate asks first, even when
    /// the Space never asks, so the setting can't be lowered to read its
    /// passwords; a refusal changes nothing.
    func testChangingWhenToAuthenticateAlwaysAsksFirst() async throws {
        var session = SessionState.Seed.preview
        session.spaces[0].settings.credentialPreferences.authentication = .never
        let space = session.spaces[0]
        let browser = BrowserStore(seed: session, credentialVault: InMemoryCredentialVault())

        let refused = BrowserCredentialSensitiveAccess(
            browser: browser, authenticator: CredentialChoiceAuthenticatorStub(result: false))
        do {
            try await refused.authorizeAuthenticationChange(in: space.id)
            XCTFail("A refused authentication must not authorize the change")
        } catch {
            XCTAssertEqual(error as? BrowserCredentialSensitiveAccessError, .authenticationDenied)
        }

        let granted = BrowserCredentialSensitiveAccess(
            browser: browser, authenticator: CredentialChoiceAuthenticatorStub(result: true))
        try await granted.authorizeAuthenticationChange(in: space.id)
    }
}

private final class CredentialChoiceAuthenticatorStub: BrowserDeviceAuthenticating {
    let result: Bool

    init(result: Bool) {
        self.result = result
    }

    func authenticate(reason: String) async throws -> Bool {
        result
    }
}
