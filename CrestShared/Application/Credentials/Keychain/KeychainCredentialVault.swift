import Foundation

/// Crest's saved passwords in the Keychain, one service per Space. Listing a
/// Space leaves out an item that no longer reads back, so one bad item never
/// makes the rest of the Space unreadable; `unreadableCredentialCount(in:)`
/// reports what was left out, and only `deleteUnreadableCredentials(in:)`
/// removes it. Writes take turns: the actor answers other calls while a write
/// waits on the Keychain, and a write never reads or restores over what
/// another is halfway through changing.
actor KeychainCredentialVault: CredentialVault {
    // MARK: - Variables

    private let store: any CredentialKeychainStoring
    private let servicePrefix: String
    private let codec = CredentialKeychainCodec()
    /// Whether passwords saved for each origin fill a page at the first, in
    /// order, those at the indexes given last reaching the hosts under their
    /// origin too, which the core answers in production.
    private let fills: @Sendable (CredentialOrigin, [CredentialOrigin], [Int]) throws -> [Bool]
    /// Whether a write holds the vault, and the writes waiting their turn.
    private var isWriting = false
    private var waitingWrites: [CheckedContinuation<Void, Never>] = []

    // MARK: - Initializers

    init(
        store: any CredentialKeychainStoring,
        servicePrefix: String = CredentialKeychainNamespace.productionPrefix,
        fills: @escaping @Sendable (CredentialOrigin, [CredentialOrigin], [Int]) throws -> [Bool] = { page, saved, _ in
            saved.map { $0 == page }
        }
    ) {
        self.store = store
        self.servicePrefix = servicePrefix
        self.fills = fills
    }

    // MARK: - Actions - Reading

    func descriptors(in spaceID: UUID) async throws -> [CredentialDescriptor] {
        try await readableDescriptors(in: spaceID)
            .sorted(by: Self.descriptorOrder)
    }

    func descriptors(
        matching origin: CredentialOrigin,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        try filling(origin, from: await readableDescriptors(in: spaceID).filter { $0.scope == .webForm })
            .sorted(by: Self.descriptorOrder)
    }

    func descriptors(
        matching protectionSpace: BrowserHTTPAuthenticationProtectionSpace,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        try filling(
            protectionSpace.origin,
            from: await readableDescriptors(in: spaceID).filter { $0.scope == protectionSpace.credentialScope }
        )
        .sorted(by: Self.descriptorOrder)
    }

    func unreadableCredentialCount(in spaceID: UUID) async throws -> Int {
        try await store.descriptorItems(in: service(for: spaceID))
            .count { !reads($0, in: spaceID) }
    }

    /// One read of the Space's service answers both, where settings asked the
    /// Keychain for the whole service twice.
    func inventory(in spaceID: UUID) async throws -> CredentialInventory {
        let items = try await store.descriptorItems(in: service(for: spaceID))
        let descriptors = items.compactMap { try? codec.descriptor(from: $0, expectedSpaceID: spaceID) }
        return CredentialInventory(
            descriptors: descriptors.sorted(by: Self.descriptorOrder),
            unreadableCount: items.count - descriptors.count)
    }

    func credential(
        id: UUID,
        in spaceID: UUID
    ) async throws -> BrowserCredential? {
        let account = id.uuidString.lowercased()
        guard
            let item = try await store.item(
                account: account,
                in: service(for: spaceID)
            )
        else {
            return nil
        }
        return try codec.credential(
            from: item,
            expectedID: id,
            expectedSpaceID: spaceID
        )
    }

    // MARK: - Actions - Writing

    func save(_ credential: BrowserCredential, in spaceID: UUID) async throws {
        let item = try codec.item(
            for: credential,
            expectedSpaceID: spaceID
        )
        try await writing {
            try await store.upsert(item, in: service(for: spaceID))
        }
    }

    /// Makes the Space hold `credentials`: writes each one that differs from
    /// what the Space holds, then removes what they leave out. Removing comes
    /// last, so a stop partway leaves every password the person keeps, as it
    /// was or as replaced. A failure undoes exactly what the replacement did.
    func replaceAll(
        _ credentials: [BrowserCredential],
        in spaceID: UUID
    ) async throws {
        let service = service(for: spaceID)
        let replacementItems = try credentials.map {
            try codec.item(for: $0, expectedSpaceID: spaceID)
        }
        let replacementAccounts = Set(replacementItems.map(\.account))
        guard replacementAccounts.count == replacementItems.count else {
            throw CredentialVaultError.malformedStoredCredential
        }
        try await writing {
            let originalItems = try await store.items(in: service)
            let originals = Dictionary(originalItems.map { ($0.account, $0) }) { first, _ in first }
            let changedItems = replacementItems.filter { originals[$0.account] != $0 }
            // An item that no longer reads back is in no inventory a caller can
            // name, so a replacement keeps it.
            let leftOutItems = originalItems.filter {
                !replacementAccounts.contains($0.account) && reads($0, in: spaceID)
            }
            var written: [CredentialKeychainItem] = []
            var removed: [CredentialKeychainItem] = []
            do {
                for item in changedItems {
                    try await store.upsert(item, in: service)
                    written.append(item)
                }
                for item in leftOutItems {
                    try await store.delete(account: item.account, in: service)
                    removed.append(item)
                }
            } catch {
                do {
                    for item in written.reversed() {
                        if let original = originals[item.account] {
                            try await store.upsert(original, in: service)
                        } else {
                            try await store.delete(account: item.account, in: service)
                        }
                    }
                    for item in removed {
                        try await store.upsert(item, in: service)
                    }
                } catch {
                    throw CredentialVaultError.atomicReplacementRestoreFailed
                }
                throw error
            }
        }
    }

    func setSynchronizable(
        _ isSynchronizable: Bool,
        in spaceID: UUID
    ) async throws {
        let service = service(for: spaceID)
        try await writing {
            let originalItems = try await store.items(in: service)
            var migratedOriginalItems: [CredentialKeychainItem] = []

            do {
                for item in originalItems
                where item.isSynchronizable != isSynchronizable && reads(item, in: spaceID) {
                    let migratedItem = try codec.migratedItem(
                        from: item,
                        isSynchronizable: isSynchronizable,
                        expectedSpaceID: spaceID
                    )
                    try await store.upsert(migratedItem, in: service)
                    migratedOriginalItems.append(item)
                }
            } catch {
                // Each item changes in place, so one that stays moved is still
                // whole, and the next change moves the rest.
                for originalItem in migratedOriginalItems.reversed() {
                    try? await store.upsert(originalItem, in: service)
                }
                throw error
            }
            // Notes follow the passwords they belong to; a note that fails to
            // move moves with the next change.
            let passwords = Set(originalItems.filter { reads($0, in: spaceID) }.map(\.account))
            let noteService = noteService(for: spaceID)
            for note in try await store.items(in: noteService)
            where passwords.contains(note.account) && note.isSynchronizable != isSynchronizable {
                try await store.upsert(
                    CredentialKeychainItem(
                        account: note.account, metadata: note.metadata, secret: note.secret,
                        isSynchronizable: isSynchronizable),
                    in: noteService)
            }
        }
    }

    func delete(id: UUID, in spaceID: UUID) async throws {
        try await writing {
            try await store.delete(
                account: id.uuidString.lowercased(),
                in: service(for: spaceID)
            )
            try await store.delete(account: id.uuidString.lowercased(), in: noteService(for: spaceID))
        }
    }

    func deleteAll(in spaceID: UUID) async throws {
        try await writing {
            try await store.deleteAll(in: service(for: spaceID))
            try await store.deleteAll(in: noteService(for: spaceID))
        }
    }

    // MARK: - Actions - Notes

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

    func deleteUnreadableCredentials(in spaceID: UUID) async throws {
        let service = service(for: spaceID)
        try await writing {
            for item in try await store.descriptorItems(in: service) where !reads(item, in: spaceID) {
                try await store.delete(account: item.account, in: service)
            }
        }
    }

    // MARK: - Actions - Turns

    /// Runs `write` once no other write holds the vault, holding it until
    /// `write` ends, when the write that waited longest takes it.
    private func writing<Result>(_ write: () async throws -> Result) async rethrows -> Result {
        if isWriting {
            await withCheckedContinuation { waitingWrites.append($0) }
        } else {
            isWriting = true
        }
        defer {
            if waitingWrites.isEmpty {
                isWriting = false
            } else {
                waitingWrites.removeFirst().resume()
            }
        }
        return try await write()
    }

    // MARK: - Actions - Items

    private func readableDescriptors(in spaceID: UUID) async throws -> [CredentialDescriptor] {
        try await store.descriptorItems(in: service(for: spaceID))
            .compactMap { try? codec.descriptor(from: $0, expectedSpaceID: spaceID) }
    }

    /// The descriptors among `descriptors` whose passwords fill a page at
    /// `origin`: those saved for it, those whose origin the core reads as it,
    /// such as an IP address an earlier import kept in another spelling, and
    /// those that reach the hosts under their origin when `origin` is one.
    private func filling(
        _ origin: CredentialOrigin,
        from descriptors: [CredentialDescriptor]
    ) throws -> [CredentialDescriptor] {
        let others = descriptors.filter { $0.origin != origin }
        let reaching = others.indices.filter { others[$0].includesSubdomains }
        let othersFill: [Bool]
        do {
            othersFill = try fills(origin, others.map(\.origin), reaching)
        } catch Rejection.invalidCredentialOrigin {
            // No page has such an origin, but if one did, its own passwords still fill it.
            othersFill = []
        }
        let filling = Set(zip(others, othersFill).filter(\.1).map(\.0.id))
        return descriptors.filter { $0.origin == origin || filling.contains($0.id) }
    }

    private func reads(_ item: CredentialKeychainDescriptorItem, in spaceID: UUID) -> Bool {
        (try? codec.descriptor(from: item, expectedSpaceID: spaceID)) != nil
    }

    private func reads(_ item: CredentialKeychainItem, in spaceID: UUID) -> Bool {
        (try? codec.descriptor(from: item, expectedSpaceID: spaceID)) != nil
    }

    private func service(for spaceID: UUID) -> String {
        CredentialKeychainNamespace.service(for: spaceID, prefix: servicePrefix)
    }

    private func noteService(for spaceID: UUID) -> String {
        CredentialKeychainNamespace.noteService(for: spaceID, prefix: servicePrefix)
    }

    /// What a note item keeps beside its text: nothing a reader needs, since
    /// its account names its password.
    private static let noteMetadata = Data("{}".utf8)

    private static func descriptorOrder(
        _ lhs: CredentialDescriptor,
        _ rhs: CredentialDescriptor
    ) -> Bool {
        let usernameOrder = lhs.username.localizedCaseInsensitiveCompare(rhs.username)
        if usernameOrder != .orderedSame {
            return usernameOrder == .orderedAscending
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
