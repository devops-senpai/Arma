import SwiftUI

/// Whether `arma passwords` may reach a Space's passwords, and the sessions
/// the person has open on it, as rows of the Arma Passwords section. Letting the terminal in asks the person to
/// authenticate first; shutting it out ends its sessions at once.
struct BrowserPasswordCommandLineRows: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    @State private var isAuthorizing = false
    private var sessions: BrowserCredentialTerminalSessions { .shared }

    private var allowsCommandLine: Binding<Bool> {
        let stored = browser.credentialPreferenceBinding(\.allowsCommandLine, in: space)
        return Binding(
            get: { stored.wrappedValue },
            set: { allows in
                guard allows else {
                    stored.wrappedValue = false
                    sessions.endAll(on: space.id)
                    return
                }
                guard !isAuthorizing else { return }
                isAuthorizing = true
                Task { @MainActor in
                    defer { isAuthorizing = false }
                    let access = BrowserCredentialSensitiveAccess(browser: browser)
                    guard (try? await access.authorizeCommandLineAccess(in: space.id)) != nil else { return }
                    stored.wrappedValue = true
                }
            })
    }

    private var openSessions: [BrowserCredentialTerminalSession] {
        sessions.sessions.filter { $0.spaceID == space.id }
    }

    // MARK: - Actions - Drawing

    var body: some View {
        Toggle("Allow command-line access", isOn: allowsCommandLine)
            .disabled(isAuthorizing)
            .help(
                "arma passwords unlock asks for Touch ID or your Mac password and opens this Space for an hour at most."
            )
            .accessibilityIdentifier("space-credential-command-line")
        ForEach(openSessions) { session in
            HStack {
                Label(
                    "Terminal unlocked until \(session.expiresAt.formatted(date: .omitted, time: .shortened))",
                    systemImage: "terminal")
                Spacer()
                Button("End") { sessions.end(session.id) }
            }
        }
    }
}
