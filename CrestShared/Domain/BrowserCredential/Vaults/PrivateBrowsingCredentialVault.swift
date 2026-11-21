import Foundation

actor PrivateBrowsingCredentialVault: CredentialVault {
    let readable: (any CredentialVault)?
    let sources: @Sendable () async -> [UUID]

    init(readingFrom readable: (any CredentialVault)? = nil, sources: @escaping @Sendable () async -> [UUID] = { [] }) {
        self.readable = readable
        self.sources = sources
    }

    func descriptors(in spaceID: UUID) async throws -> [CredentialDescriptor] {
        []
    }

    func descriptors(
        matching origin: CredentialOrigin,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        try await suggestions(matching: origin, in: spaceID)
    }

    func descriptors(
        matching protectionSpace: BrowserHTTPAuthenticationProtectionSpace,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        []
    }

    func unreadableCredentialCount(in spaceID: UUID) async throws -> Int {
        0
    }

    func credential(
        id: UUID,
        in spaceID: UUID
    ) async throws -> BrowserCredential? {
        try await suggestedCredential(id: id, in: spaceID)
    }

    func save(_ credential: BrowserCredential, in spaceID: UUID) async throws {
        throw CredentialVaultError.unavailableInPrivateBrowsing
    }

    func replaceAll(_ credentials: [BrowserCredential], in spaceID: UUID) async throws {
        throw CredentialVaultError.unavailableInPrivateBrowsing
    }

    func setSynchronizable(_ isSynchronizable: Bool, in spaceID: UUID) async throws {
        throw CredentialVaultError.unavailableInPrivateBrowsing
    }

    func delete(id: UUID, in spaceID: UUID) async throws {}

    func deleteAll(in spaceID: UUID) async throws {}

    func deleteUnreadableCredentials(in spaceID: UUID) async throws {}

}
