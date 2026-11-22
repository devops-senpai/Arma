import Foundation

extension KeychainCredentialVault {
    func notes(for id: UUID, in spaceID: UUID) async throws -> String? {
        guard let item = try await store.item(account: id.uuidString.lowercased(), in: noteService(for: spaceID)) else {
            return nil
        }
        return String(data: item.secret, encoding: .utf8)
    }

    func setNotes(_ notes: String?, for id: UUID, isSynchronizable: Bool, in spaceID: UUID) async throws {
        let account = id.uuidString.lowercased()
        let service = noteService(for: spaceID)
        guard let notes, !notes.isEmpty else {
            try await writing { try await store.delete(account: account, in: service) }
            return
        }
        let secret = Data(notes.utf8)
        guard secret.count <= credentialNotesByteLimit else { throw CredentialVaultError.notesTooLong }
        let item = CredentialKeychainItem(
            account: account, metadata: Self.noteMetadata, secret: secret, isSynchronizable: isSynchronizable)
        try await writing { try await store.upsert(item, in: service) }
    }

    func noteService(for spaceID: UUID) -> String {
        CredentialKeychainNamespace.noteService(for: spaceID, prefix: servicePrefix)
    }

    /// What a note item keeps beside its text: nothing a reader needs, since
    /// its account names its password.
    static let noteMetadata = Data("{}".utf8)
}
