import Foundation

/// A private window's passwords: none of its own, and nothing it can save.
/// It can still suggest, without changing, the passwords of the Spaces that
/// chose to be suggested in private windows, which `sources` names; each
/// appears as the private Space's own for as long as the page asks.
actor PrivateBrowsingCredentialVault: CredentialVault {
    private let readable: (any CredentialVault)?
    private let sources: @Sendable () async -> [UUID]

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
        guard let readable else { return [] }
        var suggested: [CredentialDescriptor] = []
        for source in await sources() {
            suggested += try await readable.descriptors(matching: origin, in: source)
                .map { BrowserCredential(descriptor: $0, password: "").moved(to: spaceID).descriptor }
        }
        return suggested
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
        guard let readable else { return nil }
        for source in await sources() {
            if let credential = try await readable.credential(id: id, in: source) {
                return credential.moved(to: spaceID)
            }
        }
        return nil
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

    func notes(for id: UUID, in spaceID: UUID) async throws -> String? {
        nil
    }

    func setNotes(_ notes: String?, for id: UUID, isSynchronizable: Bool, in spaceID: UUID) async throws {
        throw CredentialVaultError.unavailableInPrivateBrowsing
    }
}
