import SwiftUI

/// Whether Arma's password prompts answer on this tab: a click pauses them
/// until resumed, for a page another password manager should fill, or
/// resumes them. A timed pause is chosen from a prompt's menu.
struct SiteControlsPasswordsRow: View {
    let page: BrowserPlatformPage

    var body: some View {
        SiteControlsRow(
            page.credentialPromptsArePaused ? "Resume Passwords" : "Pause Passwords",
            symbol: page.credentialPromptsArePaused ? "play.circle" : "pause.circle",
            value: page.credentialPromptsArePaused ? String(localized: "Paused") : nil
        ) {
            if page.credentialPromptsArePaused {
                page.resumeCredentialPrompts()
            } else {
                page.pauseCredentialPrompts(for: .untilResumed)
            }
        }
        .help(
            page.credentialPromptsArePaused
                ? Text("Let Arma offer and save passwords on this tab again")
                : Text("Stop Arma offering and saving passwords on this tab, for another password manager")
        )
        .accessibilityIdentifier("site-control-passwords-pause")
    }
}
