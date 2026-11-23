import Foundation

extension BrowserRootShell {
    /// What the site controls call to open a site's passwords, and to count
    /// those the page's Space keeps for it.
    var sitePasswordsAction: BrowserOpenSitePasswordsAction {
        BrowserOpenSitePasswordsAction(
            open: openSitePasswords,
            count: { spaceID, url in
                (try? await model.browser.credentialSuggestions(for: url, in: spaceID).count) ?? 0
            })
    }

    /// Opens Settings at the Passwords page of Space `spaceID` for the site at
    /// `url`: a new password for it when the Space keeps none, or its saved
    /// passwords searched to the site.
    func openSitePasswords(_ spaceID: UUID, _ url: URL) {
        guard let space = model.browser.spaceModel(spaceID), let host = url.host(), !host.isEmpty else { return }
        let assignment = BrowserSpaceRuntimeAssignment(space: space)
        Task { @MainActor in
            let saved = (try? await model.browser.credentialSuggestions(for: url, in: spaceID)) ?? []
            spaceSettingsPresentation.present(
                BrowserSettingsPasswordsRequest(
                    route: BrowserSettingsPasswordsRoute(site: host, addsPassword: saved.isEmpty)),
                assignment: assignment)
            model.browser.openSettings()
            model.pages.select()
        }
    }
}
