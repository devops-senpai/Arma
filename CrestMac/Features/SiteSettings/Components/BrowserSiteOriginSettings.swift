import SwiftUI

struct BrowserSiteOriginSettings: View {
    let page: BrowserPage
    let origin: SiteOrigin
    var reviewCertificate: (() -> Void)?
    let permissionCenter: BrowserSitePermissionCenter
    @Binding var isExpanded: Bool

    @Environment(\.openSitePasswords) private var openSitePasswords
    /// How many passwords the page's Space keeps for the site, once counted.
    @State private var savedCount: Int?

    /// Pauses Arma's password prompts on this tab, for another password
    /// manager, for a time or until resumed; resumes them while paused.
    @ViewBuilder
    private var pauseControl: some View {
        if page.areCredentialPromptsPaused {
            Button {
                page.resumeCredentialPrompts()
            } label: {
                Label(resumeTitle, systemImage: "play.circle")
            }
            .buttonStyle(.plain)
        } else {
            Menu {
                Group {
                    ForEach(BrowserCredentialPauseLength.all) { length in
                        Button(length.title, systemImage: length.systemImage) {
                            page.pauseCredentialPrompts(for: length)
                        }
                    }
                }
                .crestMenuActionLabelStyle()
            } label: {
                Label("Pause Passwords on This Tab", systemImage: "pause.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var resumeTitle: String {
        guard let until = page.credentialPromptsPausedUntil else { return String(localized: "Resume Passwords") }
        return String(localized: "Resume Passwords (paused until \(until.formatted(date: .omitted, time: .shortened)))")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CrestSpacing.medium) {
            Divider()
            BrowserSiteSecuritySection(
                page: page,
                origin: origin,
                reviewCertificate: reviewCertificate
            )
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
                pauseControl
                    .font(.caption)
                    .accessibilityIdentifier("site-controls-pause-passwords")
            }
            Divider()
            BrowserEngineSitePermissionsSection(
                page: page,
                origin: origin,
                permissionCenter: permissionCenter,
                isExpanded: $isExpanded
            )
        }
    }
}
