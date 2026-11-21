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
