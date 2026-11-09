import Foundation

extension CredentialPreferences {
    // MARK: - Variables

    /// A seeded Space offers to save passwords and sync them with iCloud,
    /// never to the system's passwords, unless told otherwise.
    static let seeded = CredentialPreferences(
        isEnabled: true, syncsCrestPasswordsWithICloud: true, alsoOffersSaveToSystemPasswords: false,
        savePromptSeconds: defaultSavePromptSeconds, neverSavedSites: [], authentication: .never,
        suggestsInPrivateWindows: false, generation: .standard, allowsCommandLine: false)
}

extension PasswordGeneration {
    /// Sixteen characters from every group, as the core generates by default.
    static let standard = PasswordGeneration(
        length: defaultLength, lowercase: true, uppercase: true, numbers: true, symbols: true)
}
