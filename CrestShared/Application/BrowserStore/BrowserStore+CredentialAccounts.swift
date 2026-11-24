import Foundation

// MARK: - Never-saved sites

extension BrowserStore {
    /// Space `spaceID`'s never-saved sites, read afresh each time a page asks,
    /// so an edit in Settings applies to pages already open.
    func neverSavedSites(of spaceID: UUID) -> @MainActor () -> [NeverSavedSite] {
        { [weak self] in self?.spaceModel(spaceID)?.settings.credentialPreferences.neverSavedSites ?? [] }
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
}

// MARK: - Accounts

extension BrowserStore {
    /// The longest category name a saved password keeps.
    static let credentialCategoryLength = 64

    /// `name` as a saved password keeps it for its category: trimmed and no
    /// longer than `credentialCategoryLength`, or nil when nothing is left.
    static func credentialCategory(_ name: String) -> String? {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(credentialCategoryLength)).nilIfEmpty
    }

    /// The categories `descriptors` are filed under, each once whatever its
    /// case, in alphabetical order.
    static func credentialCategories(in descriptors: [CredentialDescriptor]) -> [String] {
        var names: [String] = []
        for name in descriptors.compactMap(\.category)
        where !names.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            names.append(name)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
}
