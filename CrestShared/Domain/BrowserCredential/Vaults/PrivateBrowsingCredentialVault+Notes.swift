import Foundation

extension PrivateBrowsingCredentialVault {
    func notes(for id: UUID, in spaceID: UUID) async throws -> String? {
        nil
    }

    func setNotes(_ notes: String?, for id: UUID, isSynchronizable: Bool, in spaceID: UUID) async throws {
        throw CredentialVaultError.unavailableInPrivateBrowsing
    }
}
