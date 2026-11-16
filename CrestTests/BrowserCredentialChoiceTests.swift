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

    /// A private window suggests the passwords of a Space that chose to be
    /// suggested there, and of no other, and never saves one: its vault
    /// refuses the write and the Space's own vault is left as it was.
    func testAPrivateWindowSuggestsOnlyChosenSpacesPasswordsAndSavesNone() async throws {
        let vault = InMemoryCredentialVault()
        let browser = BrowserStore(seed: .preview, credentialVault: vault)
        let space = try XCTUnwrap(browser.spaceModels.first)
        let url = try XCTUnwrap(URL(string: "https://accounts.example.com/sign-in"))
        _ = try await browser.saveCredential(username: "person", password: "secret", for: url, in: space.id)
        let privateBrowser = BrowserStore.privateBrowsing(core: browser.core, passwordsFrom: browser)
        let privateSpaceID = privateBrowser.selectedSpaceID

        let unchosen = try await privateBrowser.credentialSuggestions(for: url, in: privateSpaceID)
        XCTAssertTrue(unchosen.isEmpty)

        var preferences = space.settings.credentialPreferences
        preferences.suggestsInPrivateWindows = true
        browser.updateCredentialPreferences(preferences, in: space.id)
        let suggested = try await privateBrowser.credentialSuggestions(for: url, in: privateSpaceID)
        XCTAssertEqual(suggested.map(\.username), ["person"])
        XCTAssertEqual(suggested.map(\.spaceID), [privateSpaceID])

        do {
            _ = try await privateBrowser.saveCredential(
                username: "new", password: "other", for: url, in: privateSpaceID)
            XCTFail("A private window must not save a password")
        } catch {
            XCTAssertEqual(error as? CredentialVaultError, .unavailableInPrivateBrowsing)
        }
        let kept = try await vault.descriptors(in: space.id)
        XCTAssertEqual(kept.map(\.username), ["person"])
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
