import SwiftUI

/// The page's site's passwords in its site controls: Manage Passwords, with
/// how many the page's Space keeps for the site.
struct BrowserSitePasswordControls: View {
    let page: BrowserPage

    @Environment(\.openSitePasswords) private var openSitePasswords

    /// How many passwords the page's Space keeps for the site, once counted.
    @State private var savedCount: Int?

    var body: some View {
        if let openSitePasswords, let url = page.live.displayURL, page.live.security.isSecure {
            Divider()
            Button {
                openSitePasswords(page.spaceID, url)
            } label: {
                HStack(spacing: CrestSpacing.small) {
                    Label("Manage Passwords", systemImage: "key")
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: CrestSpacing.small)
                    if let savedCount {
                        Text(
                            savedCount == 0
                                ? String(localized: "None saved") : String(localized: "\(savedCount) saved")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("site-controls-manage-passwords")
            .task(id: url.host()) {
                savedCount = await openSitePasswords.count(page.spaceID, url)
            }
        }
    }
}
