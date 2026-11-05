import Foundation

// MARK: - Suggestion Loading

extension BrowserStore: BrowserCredentialSuggestionLoading {
    func credentialSuggestions(
        for origin: CredentialOrigin,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        guard let url = URL(string: origin.description) else {
            throw CredentialVaultError.invalidOrigin
        }
        return try await credentialSuggestions(for: url, in: spaceID)
    }
}

// MARK: - Lookup

extension BrowserStore {
    func credentialSuggestions(for url: URL) async throws -> [CredentialDescriptor] {
        guard let spaceID = shownSpace?.id else {
            throw CredentialVaultError.missingSpace
        }
        return try await credentialSuggestions(for: url, in: spaceID)
    }

    /// The passwords the Space's group keeps: the ones its primary keeps for
    /// the group and the ones each Sub-Space saved before it joined.
    func savedCredentialDescriptors(in spaceID: UUID) async throws -> [CredentialDescriptor] {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        return try await groupDescriptors(of: spaceID) { try await credentialVault.descriptors(in: $0) }
    }

    /// How many saved passwords of the Space's group no longer read back,
    /// which every list and suggestion leaves out.
    func unreadableCredentialCount(in spaceID: UUID) async throws -> Int {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        var count = 0
        for vault in credentialSpaceIDs(of: spaceID) {
            count += try await credentialVault.unreadableCredentialCount(in: vault)
        }
        return count
    }

    func credentialSuggestions(
        for url: URL,
        in spaceID: UUID
    ) async throws -> [CredentialDescriptor] {
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        // A private window's vault holds only what other Spaces chose to suggest there.
        guard space.settings.credentialPreferences.isEnabled || isPrivateBrowsing else { return [] }
        guard let origin = CredentialOrigin(url: url) else {
            throw CredentialVaultError.invalidOrigin
        }
        guard origin.isSecure else { return [] }
        return try await groupDescriptors(of: spaceID) {
            try await credentialVault.descriptors(matching: origin, in: $0)
        }
    }

    func credential(id: UUID) async throws -> BrowserCredential? {
        guard let spaceID = shownSpace?.id else {
            throw CredentialVaultError.missingSpace
        }
        return try await credential(id: id, in: spaceID)
    }

    /// The password `id` names among the ones the Space's group keeps.
    func credential(id: UUID, in spaceID: UUID) async throws -> BrowserCredential? {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        for vault in credentialSpaceIDs(of: spaceID) {
            if let credential = try await credentialVault.credential(id: id, in: vault) { return credential }
        }
        return nil
    }

    func credentialInventory(in spaceID: UUID) async throws -> [BrowserCredential] {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        let descriptors = try await credentialVault.descriptors(in: spaceID)
        var credentials: [BrowserCredential] = []
        credentials.reserveCapacity(descriptors.count)
        for descriptor in descriptors {
            guard
                let credential = try await credentialVault.credential(
                    id: descriptor.id,
                    in: spaceID
                ),
                credential.descriptor == descriptor,
                credential.descriptor.spaceID == spaceID
            else {
                throw BrowserCredentialSensitiveAccessError.malformedCredentialInventory
            }
            credentials.append(credential)
        }
        return credentials
    }

    func httpAuthenticationCredential(
        for protectionSpace: BrowserHTTPAuthenticationProtectionSpace,
        in spaceID: UUID
    ) async throws -> BrowserCredential? {
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        guard space.settings.credentialPreferences.isEnabled else { return nil }
        guard protectionSpace.origin.isSecure else { return nil }
        let descriptors = try await groupDescriptors(of: spaceID) {
            try await credentialVault.descriptors(matching: protectionSpace, in: $0)
        }
        // Without a recency answer from the core, nothing is filled.
        guard let descriptor = try? core.mostRecentCredential(descriptors) else {
            return nil
        }
        return try await credentialVault.credential(id: descriptor.id, in: descriptor.spaceID)
    }

    // MARK: - Actions - Groups

    /// What `read` answers for each vault of the group of `spaceID`, the
    /// primary's first.
    private func groupDescriptors(
        of spaceID: UUID, _ read: (UUID) async throws -> [CredentialDescriptor]
    ) async throws -> [CredentialDescriptor] {
        var descriptors: [CredentialDescriptor] = []
        for vault in credentialSpaceIDs(of: spaceID) { descriptors += try await read(vault) }
        return descriptors
    }

    /// The vault of the group of `spaceID` that keeps `existing`, or the one
    /// that keeps the group's new passwords. Throws when `existing` belongs to
    /// another group.
    private func credentialVaultID(of spaceID: UUID, keeping existing: CredentialDescriptor?) throws -> UUID {
        let vaults = credentialSpaceIDs(of: spaceID)
        guard let existing else { return vaults[0] }
        guard vaults.contains(existing.spaceID) else {
            throw CredentialVaultError.spaceMismatch(expected: vaults[0], actual: existing.spaceID)
        }
        return existing.spaceID
    }
}

// MARK: - Generated passwords and system Passwords

extension BrowserStore {
    /// How to compose a generated password as `generation` describes, or as
    /// Space `spaceID` generates them. The password itself is drawn natively,
    /// so it never enters the core.
    func strongPasswordRecipe(
        _ generation: PasswordGeneration? = nil, in spaceID: UUID? = nil
    ) throws -> StrongPasswordRecipe {
        do {
            let chosen = generation ?? spaceID.flatMap { spaceModel($0)?.settings.credentialPreferences.generation }
            return try core.query(StrongPassword(generation: chosen))
        } catch {
            throw BrowserStrongPasswordGenerationError.unavailable
        }
    }

    /// Whether this launch can offer saved passwords to the system's Passwords
    /// app. A core that refuses the platform's facts reports it unsupported.
    var systemPasswordWriteThroughAvailability: SystemPasswordWriteThroughAvailability {
        (try? core.query(BrowserSystemPasswordWriteThroughSystem.facts()))?.availability ?? .unsupportedPlatform
    }

    /// Whether a save prompt in a Space with these preferences goes on to
    /// offer the password to the system's Passwords app. A core that cannot
    /// answer does not offer it.
    func offersSystemPasswordWriteThrough(for preferences: CredentialPreferences) -> Bool {
        let offer = SystemPasswordOffer(
            spaceOffersSystemPasswords: preferences.alsoOffersSaveToSystemPasswords,
            availability: systemPasswordWriteThroughAvailability, isPrivateBrowsing: isPrivateBrowsing)
        return (try? core.query(offer))?.offers ?? false
    }
}

// MARK: - Preferences

extension BrowserStore {
    func updateCredentialPreferences(
        _ preferences: CredentialPreferences,
        in spaceID: UUID
    ) {
        sendSpaceSettings(
            SetCredentialPreferences(
                workspaceID: profileSettingsBrowser.family.workspaceID, spaceID: spaceID, preferences: preferences))
    }

    /// Stops Space `spaceID`, and its group, offering to save passwords on
    /// the website `site` names, such as `example.com` or `*.example.com`, in
    /// place of `replacing` when a person edits an entry. Throws the rule that
    /// refused it, such as `InvalidNeverSavedSite`.
    func neverSaveSite(
        _ site: String, includesSubdomains: Bool, replacing: NeverSavedSite? = nil, in spaceID: UUID
    ) throws(Rejection) {
        let owner = profileSettingsBrowser
        try owner.family.commit(
            NeverSaveSite(
                workspaceID: owner.family.workspaceID, spaceID: spaceID, site: site,
                includesSubdomains: includesSubdomains, replacing: replacing),
            from: owner)
    }

    /// Lets Space `spaceID`, and its group, offer to save passwords on `site`
    /// again.
    func forgetNeverSavedSite(_ site: NeverSavedSite, in spaceID: UUID) {
        sendSpaceSettings(
            ForgetNeverSavedSite(workspaceID: profileSettingsBrowser.family.workspaceID, spaceID: spaceID, site: site))
    }

    func setCrestPasswordSynchronization(
        _ isSynchronizable: Bool,
        in spaceID: UUID
    ) async throws {
        // The vault write and its preference belong to the store that owns
        // the Space's credential settings, which may be a borrowed source.
        let owner = profileSettingsBrowser
        guard owner === self else {
            try await owner.setCrestPasswordSynchronization(isSynchronizable, in: spaceID)
            return
        }
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        guard space.settings.credentialPreferences.syncsCrestPasswordsWithICloud != isSynchronizable else {
            return
        }
        let assignment = BrowserSpaceRuntimeAssignment(space: space)

        for vault in credentialSpaceIDs(of: spaceID) {
            try await credentialVault.setSynchronizable(isSynchronizable, in: vault)
        }
        guard let current = spaceModel(matching: assignment)?.settings.credentialPreferences else {
            throw CredentialVaultError.missingSpace
        }
        var preferences = current
        preferences.syncsCrestPasswordsWithICloud = isSynchronizable
        // The native credential operation completed for this profile. Persist
        // its corresponding policy through the same session authority.
        let sent = SetCredentialPreferences(workspaceID: family.workspaceID, spaceID: spaceID, preferences: preferences)
        if !family.send(sent, from: self),
            spaceModel(spaceID)?.settings.credentialPreferences != preferences
        {
            throw CredentialVaultError.preferenceUpdateFailed
        }
    }

}

// MARK: - Saving

extension BrowserStore {
    /// The core matches the account and plans the save from descriptors
    /// alone. The stored password is compared here and only the answer is
    /// passed on. A core that cannot answer fails the plan: nothing is saved.
    func credentialSavePlan(
        for candidate: BrowserCredentialSaveCandidate,
        in spaceID: UUID,
        now: Date = .now
    ) async throws -> any BrowserCredentialSavePlan {
        try validateCredentialSaveCandidate(candidate, in: spaceID, now: now)
        let descriptors = try await groupDescriptors(of: spaceID) {
            try await credentialVault.descriptors(matching: candidate.origin, in: $0)
        }
        try validateCredentialSaveCandidate(candidate, in: spaceID, now: now)
        let descriptor: CredentialDescriptor?
        do {
            descriptor = try core.credentialSaveMatch(username: candidate.username, in: descriptors)
        } catch {
            throw CredentialVaultError.saveDecisionUnavailable
        }
        var storedPasswordMatches: Bool?
        if let descriptor {
            let credential = try await credentialVault.credential(
                id: descriptor.id,
                in: descriptor.spaceID
            )
            try validateCredentialSaveCandidate(candidate, in: spaceID, now: now)
            storedPasswordMatches = credential.map { $0.password == candidate.password }
        }
        let stored = descriptor.flatMap { descriptor in
            storedPasswordMatches.map {
                CredentialStoredComparison(id: descriptor.id, passwordMatches: $0)
            }
        }
        guard let plan = try? core.query(CredentialSave(matchID: descriptor?.id, stored: stored)),
            plan.kind == .create || plan.id == descriptor?.id
        else { throw CredentialVaultError.saveDecisionUnavailable }
        switch (plan.kind, descriptor) {
        case (.create, _): return BrowserCredentialCreatePlan()
        case (.update, let descriptor?): return BrowserCredentialUpdatePlan(existing: descriptor)
        case (.alreadyStored, let descriptor?): return BrowserCredentialAlreadyStoredPlan(existing: descriptor)
        default: throw CredentialVaultError.saveDecisionUnavailable
        }
    }

    func commitCredentialSave(
        _ candidate: BrowserCredentialSaveCandidate,
        in spaceID: UUID,
        now: Date = .now
    ) async throws -> BrowserCredentialSaveResult {
        try validateCredentialSaveCandidate(candidate, in: spaceID, now: now)
        let key = BrowserCredentialSaveKey(candidate: candidate, spaceID: spaceID)
        let precedingCompletion = credentialSaveOperations[key]?.completion
        let operationID = UUID()
        let task = Task { @MainActor [self] in
            if let precedingCompletion {
                await precedingCompletion.value
            }
            return try await performCredentialSave(
                candidate,
                in: spaceID,
                now: now
            )
        }
        let completion = Task {
            _ = try? await task.value
        }
        credentialSaveOperations[key] = BrowserCredentialSaveOperation(
            id: operationID,
            completion: completion
        )
        defer {
            if credentialSaveOperations[key]?.id == operationID {
                credentialSaveOperations[key] = nil
            }
        }
        return try await task.value
    }

    @discardableResult
    func saveCredential(
        username: String,
        password: String,
        for url: URL,
        displayName: String? = nil,
        isSynchronizable: Bool? = nil,
        now: Date = Date()
    ) async throws -> CredentialDescriptor {
        guard let spaceID = shownSpace?.id else {
            throw CredentialVaultError.missingSpace
        }
        return try await saveCredential(
            username: username,
            password: password,
            for: url,
            in: spaceID,
            displayName: displayName,
            replacing: nil,
            isSynchronizable: isSynchronizable,
            now: now
        )
    }

    @discardableResult
    func saveCredential(
        username: String,
        password: String,
        for url: URL,
        in spaceID: UUID,
        displayName: String? = nil,
        replacing existing: CredentialDescriptor? = nil,
        isSynchronizable: Bool? = nil,
        email: String? = nil,
        category: String? = nil,
        includesSubdomains: Bool? = nil,
        now: Date = Date()
    ) async throws -> CredentialDescriptor {
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        guard !isPrivateBrowsing else {
            throw CredentialVaultError.unavailableInPrivateBrowsing
        }
        guard space.settings.credentialPreferences.isEnabled else {
            throw CredentialVaultError.credentialManagerDisabled
        }
        let resolvedSynchronization =
            isSynchronizable
            ?? space.settings.credentialPreferences.syncsCrestPasswordsWithICloud
        guard let origin = CredentialOrigin(url: url) else {
            throw CredentialVaultError.invalidOrigin
        }
        guard origin.isSecure else {
            throw CredentialVaultError.insecureOrigin
        }

        // A group keeps new passwords in its primary, and each one where it is.
        let vaultID = try credentialVaultID(of: spaceID, keeping: existing)
        let descriptor: CredentialDescriptor
        if var existing {
            // A password saved on the site above, reaching this page, is updated where it is.
            guard existing.origin == origin || existing.includesSubdomains && reaches(existing.origin, origin) else {
                throw CredentialVaultError.invalidOrigin
            }
            existing.username = username
            existing.displayName = displayName?.nilIfEmpty ?? existing.displayName
            existing.email = email.map { $0.nilIfEmpty } ?? existing.email
            existing.category = category.map { Self.credentialCategory($0) } ?? existing.category
            existing.includesSubdomains = try subdomainReach(
                includesSubdomains ?? existing.includesSubdomains, from: existing.origin)
            existing.updatedAt = now
            existing.isSynchronizable = resolvedSynchronization
            descriptor = existing
        } else {
            descriptor = CredentialDescriptor(
                spaceID: vaultID,
                origin: origin,
                username: username,
                displayName: displayName?.nilIfEmpty,
                email: email?.nilIfEmpty,
                category: category.flatMap { Self.credentialCategory($0) },
                includesSubdomains: try subdomainReach(includesSubdomains ?? false, from: origin),
                createdAt: now,
                isSynchronizable: resolvedSynchronization
            )
        }
        try await credentialVault.save(
            BrowserCredential(descriptor: descriptor, password: password),
            in: vaultID
        )
        return descriptor
    }

    @discardableResult
    func saveHTTPAuthenticationCredential(
        username: String,
        password: String,
        protectionSpace: BrowserHTTPAuthenticationProtectionSpace,
        in spaceID: UUID,
        replacing existing: CredentialDescriptor? = nil,
        now: Date = Date()
    ) async throws -> CredentialDescriptor {
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        guard !isPrivateBrowsing else {
            throw CredentialVaultError.unavailableInPrivateBrowsing
        }
        guard space.settings.credentialPreferences.isEnabled else {
            throw CredentialVaultError.credentialManagerDisabled
        }
        guard protectionSpace.origin.isSecure else {
            throw CredentialVaultError.insecureOrigin
        }

        let vaultID = try credentialVaultID(of: spaceID, keeping: existing)
        let descriptor: CredentialDescriptor
        if var existing {
            guard existing.origin == protectionSpace.origin,
                existing.scope == protectionSpace.credentialScope
            else {
                throw CredentialVaultError.invalidOrigin
            }
            existing.username = username
            existing.updatedAt = now
            existing.lastUsedAt = now
            existing.isSynchronizable =
                space.settings.credentialPreferences.syncsCrestPasswordsWithICloud
            descriptor = existing
        } else {
            descriptor = CredentialDescriptor(
                spaceID: vaultID,
                origin: protectionSpace.origin,
                scope: protectionSpace.credentialScope,
                username: username,
                createdAt: now,
                lastUsedAt: now,
                isSynchronizable:
                    space.settings.credentialPreferences.syncsCrestPasswordsWithICloud
            )
        }
        try await credentialVault.save(
            BrowserCredential(descriptor: descriptor, password: password),
            in: vaultID
        )
        return descriptor
    }

    func deleteCredential(id: UUID) async throws {
        guard let spaceID = shownSpace?.id else {
            throw CredentialVaultError.missingSpace
        }
        try await deleteCredential(id: id, in: spaceID)
    }

    /// Deletes the password `id` names from whichever vault of the Space's
    /// group keeps it.
    func deleteCredential(id: UUID, in spaceID: UUID) async throws {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        for vault in credentialSpaceIDs(of: spaceID) {
            guard try await credentialVault.descriptors(in: vault).contains(where: { $0.id == id }) else { continue }
            try await credentialVault.delete(id: id, in: vault)
        }
    }

    func deleteUnreadableCredentials(in spaceID: UUID) async throws {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        for vault in credentialSpaceIDs(of: spaceID) {
            try await credentialVault.deleteUnreadableCredentials(in: vault)
        }
    }

    func replaceCredentialInventory(
        _ credentials: [BrowserCredential],
        in spaceID: UUID
    ) async throws {
        guard spaceModel(spaceID) != nil else {
            throw CredentialVaultError.missingSpace
        }
        guard !isPrivateBrowsing else {
            throw CredentialVaultError.unavailableInPrivateBrowsing
        }
        for credential in credentials {
            guard credential.descriptor.spaceID == spaceID else {
                throw CredentialVaultError.spaceMismatch(
                    expected: spaceID,
                    actual: credential.descriptor.spaceID
                )
            }
        }
        try await credentialVault.replaceAll(credentials, in: spaceID)
    }

    private func performCredentialSave(
        _ candidate: BrowserCredentialSaveCandidate,
        in spaceID: UUID,
        now: Date
    ) async throws -> BrowserCredentialSaveResult {
        let plan = try await credentialSavePlan(
            for: candidate,
            in: spaceID,
            now: now
        )
        return try await plan.commit(candidate, in: spaceID, now: now, on: self)
    }

    /// Saves `candidate` in the Space `spaceID`, in place of `existing` when
    /// it names the account the candidate changes.
    func saveCredential(
        _ candidate: BrowserCredentialSaveCandidate,
        in spaceID: UUID,
        replacing existing: CredentialDescriptor?,
        now: Date
    ) async throws -> CredentialDescriptor {
        guard let url = URL(string: candidate.origin.description) else {
            throw CredentialVaultError.invalidOrigin
        }
        return try await saveCredential(
            username: candidate.username,
            password: candidate.password,
            for: url,
            in: spaceID,
            replacing: existing,
            email: candidate.email,
            category: candidate.category ?? "",
            includesSubdomains: candidate.includesSubdomains,
            now: now
        )
    }

    private func validateCredentialSaveCandidate(
        _ candidate: BrowserCredentialSaveCandidate,
        in spaceID: UUID,
        now: Date
    ) throws {
        guard let space = spaceModel(spaceID) else {
            throw CredentialVaultError.missingSpace
        }
        guard !isPrivateBrowsing else {
            throw CredentialVaultError.unavailableInPrivateBrowsing
        }
        guard space.settings.credentialPreferences.isEnabled else {
            throw CredentialVaultError.credentialManagerDisabled
        }
        let check = CredentialSaveCheck(
            origin: candidate.origin, topLevelOrigin: candidate.topLevelOrigin,
            submittedAt: candidate.submittedAt.timeIntervalSince1970, now: now.timeIntervalSince1970)
        switch (try? core.query(check))?.validity {
        case .accepted: return
        case .insecureOrigin: throw CredentialVaultError.insecureOrigin
        case .stale: throw CredentialVaultError.staleSaveCandidate
        case nil: throw CredentialVaultError.saveDecisionUnavailable
        }
    }
}

// MARK: - Accounts

extension BrowserStore {
    /// The vaults whose passwords a private window suggests: those of every
    /// Space that keeps passwords and chose to be suggested in private
    /// windows, with the rest of its group.
    func spacesSuggestingPasswordsInPrivateWindows() -> [UUID] {
        guard !isPrivateBrowsing else { return [] }
        var vaults: [UUID] = []
        for space in spaceModels {
            let preferences = space.settings.credentialPreferences
            guard preferences.isEnabled, preferences.suggestsInPrivateWindows else { continue }
            for vault in credentialSpaceIDs(of: space.id) where !vaults.contains(vault) { vaults.append(vault) }
        }
        return vaults
    }

    /// The notes kept with the saved password `descriptor` names, as secret as
    /// the password.
    func credentialNotes(for descriptor: CredentialDescriptor) async throws -> String? {
        try await credentialVault.notes(for: descriptor.id, in: descriptor.spaceID)
    }

    /// Keeps `notes` with the saved password `descriptor` names, synced with
    /// iCloud as the password is. Nil or empty notes remove them; notes over
    /// `credentialNotesByteLimit` bytes are refused.
    func setCredentialNotes(_ notes: String?, for descriptor: CredentialDescriptor) async throws {
        guard !isPrivateBrowsing else { throw CredentialVaultError.unavailableInPrivateBrowsing }
        try await credentialVault.setNotes(
            notes?.nilIfEmpty, for: descriptor.id, isSynchronizable: descriptor.isSynchronizable,
            in: descriptor.spaceID)
    }

    /// Makes each of the saved passwords `descriptors` name reach, or stop
    /// reaching, the hosts under its origin, as a site's Include subdomains
    /// says. Throws the core's refusal for a public suffix.
    func setSubdomainReach(_ includes: Bool, for descriptors: [CredentialDescriptor]) async throws {
        guard !isPrivateBrowsing else { throw CredentialVaultError.unavailableInPrivateBrowsing }
        for descriptor in descriptors where descriptor.includesSubdomains != includes {
            guard var credential = try await credentialVault.credential(id: descriptor.id, in: descriptor.spaceID)
            else { continue }
            credential.descriptor.includesSubdomains = try subdomainReach(includes, from: descriptor.origin)
            credential.descriptor.updatedAt = .now
            try await credentialVault.save(credential, in: descriptor.spaceID)
        }
    }

    /// The longest category name a saved password keeps.
    static let credentialCategoryLength = 64

    /// `name` as a saved password keeps it for its category: trimmed and no
    /// longer than `credentialCategoryLength`, or nil when nothing is left.
    static func credentialCategory(_ name: String) -> String? {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(credentialCategoryLength)).nilIfEmpty
    }

    /// Whether a password saved for `saved`, reaching its subdomains, fills a
    /// page at `page`, as the core answers.
    private func reaches(_ saved: CredentialOrigin, _ page: CredentialOrigin) -> Bool {
        (try? core.fills(page, from: [saved], reaching: [0]))?.first ?? false
    }

    /// Whether a password saved for `origin` may also fill the hosts under it,
    /// as the core answers; never for a public suffix such as `github.io`.
    func allowsSubdomainReach(from origin: CredentialOrigin) -> Bool {
        (try? core.query(CredentialSubdomainReach(origin: origin)))?.isAllowed ?? false
    }

    /// `includes`, once the core agrees a password saved for `origin` may
    /// reach the hosts under it. Throws the core's refusal, such as
    /// `SubdomainsOfPublicSuffix`.
    private func subdomainReach(_ includes: Bool, from origin: CredentialOrigin) throws -> Bool {
        guard includes else { return false }
        return try core.query(CredentialSubdomainReach(origin: origin)).isAllowed
    }
}
