import SwiftUI

// MARK: - Types

/// What a Space's Passwords page does on arrival for a site: lists only the
/// site's saved passwords, or starts a new one for it when it has none.
struct BrowserSettingsPasswordsRoute: Equatable, Sendable {
    let id = UUID()
    let site: String
    let addsPassword: Bool
}

/// Opens a Space's Passwords page for one site, from the page's site controls.
struct BrowserSettingsPasswordsRequest: BrowserSettingsRequest {
    // MARK: - Variables

    let route: BrowserSettingsPasswordsRoute

    // MARK: - Actions - Route

    @MainActor
    func apply(to tabState: BrowserSettingsTabState, spaceID: UUID?) {
        guard let spaceID else { return }
        tabState.showSpace(spaceID, tab: .passwords)
        tabState.passwordsRoute = route
    }
}

/// Opens the Passwords page of the page's Space for the site at a URL: a new
/// password for it when the Space keeps none, or the Space's saved passwords
/// searched to the site. It also counts the passwords the Space keeps for the
/// site, which the site controls show.
struct BrowserOpenSitePasswordsAction {
    let open: @MainActor (UUID, URL) -> Void
    let count: @MainActor (UUID, URL) async -> Int

    @MainActor
    func callAsFunction(_ spaceID: UUID, _ url: URL) {
        open(spaceID, url)
    }
}

private struct BrowserOpenSitePasswordsKey: EnvironmentKey {
    static let defaultValue: BrowserOpenSitePasswordsAction? = nil
}

extension EnvironmentValues {
    var openSitePasswords: BrowserOpenSitePasswordsAction? {
        get { self[BrowserOpenSitePasswordsKey.self] }
        set { self[BrowserOpenSitePasswordsKey.self] = newValue }
    }
}
