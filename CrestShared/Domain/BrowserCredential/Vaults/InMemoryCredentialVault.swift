import Foundation

actor InMemoryCredentialVault: CredentialVault {
    private var credentialsBySpace: [UUID: [UUID: BrowserCredential]] = [:]
    private var notesBySpace: [UUID: [UUID: String]] = [:]

    func descriptors(in spaceID: UUID) -> [CredentialDescriptor] {
        sortedDescriptors(
            credentialsBySpace[spaceID, default: [:]].values.map(\.descriptor)
        )
    }

    func descriptors(
        matching origin: CredentialOrigin,
        in spaceID: UUID
    ) -> [CredentialDescriptor] {
        sortedDescriptors(
            credentialsBySpace[spaceID, default: [:]].values
                .filter {
                    $0.descriptor.origin == origin
                        && $0.descriptor.scope == .webForm
                }
                .map(\.descriptor)
        )
    }

    func descriptors(
        matching protectionSpace: BrowserHTTPAuthenticationProtectionSpace,
        in spaceID: UUID
    ) -> [CredentialDescriptor] {
        sortedDescriptors(
            credentialsBySpace[spaceID, default: [:]].values
                .filter {
                    $0.descriptor.origin == protectionSpace.origin
                        && $0.descriptor.scope == protectionSpace.credentialScope
                }
                .map(\.descriptor)
        )
    }

    /// Every credential this vault holds reads back.
    func unreadableCredentialCount(in spaceID: UUID) -> Int {
        0
    }

    func credential(id: UUID, in spaceID: UUID) -> BrowserCredential? {
        credentialsBySpace[spaceID]?[id]
    }

    func save(_ credential: BrowserCredential, in spaceID: UUID) throws {
        guard credential.descriptor.spaceID == spaceID else {
            throw CredentialVaultError.spaceMismatch(
                expected: spaceID,
                actual: credential.descriptor.spaceID
            )
        }
        credentialsBySpace[spaceID, default: [:]][credential.descriptor.id] = credential
    }

    func replaceAll(_ credentials: [BrowserCredential], in spaceID: UUID) throws {
        for credential in credentials where credential.descriptor.spaceID != spaceID {
            throw CredentialVaultError.spaceMismatch(
                expected: spaceID,
                actual: credential.descriptor.spaceID
            )
        }
        credentialsBySpace[spaceID] = Dictionary(
            uniqueKeysWithValues: credentials.map { ($0.descriptor.id, $0) }
        )
    }

    func setSynchronizable(_ isSynchronizable: Bool, in spaceID: UUID) {
        guard var credentials = credentialsBySpace[spaceID] else { return }
        for id in credentials.keys {
            credentials[id]?.descriptor.isSynchronizable = isSynchronizable
        }
        credentialsBySpace[spaceID] = credentials
    }

    func delete(id: UUID, in spaceID: UUID) {
        notesBySpace[spaceID]?[id] = nil
        credentialsBySpace[spaceID]?[id] = nil
        if credentialsBySpace[spaceID]?.isEmpty == true {
            credentialsBySpace[spaceID] = nil
        }
    }

    func deleteAll(in spaceID: UUID) {
        notesBySpace[spaceID] = nil
        credentialsBySpace[spaceID] = nil
    }

    func deleteUnreadableCredentials(in spaceID: UUID) {}

    func notes(for id: UUID, in spaceID: UUID) -> String? {
        notesBySpace[spaceID]?[id]
    }

    func setNotes(_ notes: String?, for id: UUID, isSynchronizable: Bool, in spaceID: UUID) {
        notesBySpace[spaceID, default: [:]][id] = notes?.isEmpty == false ? notes : nil
    }

    private func sortedDescriptors(_ descriptors: [CredentialDescriptor]) -> [CredentialDescriptor] {
        descriptors.sorted {
            let usernameOrder = $0.username.localizedCaseInsensitiveCompare($1.username)
            if usernameOrder != .orderedSame {
                return usernameOrder == .orderedAscending
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
