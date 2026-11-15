import AppKit

/// `arma passwords`, run in the app over the same vault Settings › Passwords
/// uses. Every action but `unlock`, `status` and `generate` needs a session
/// the person opened with Touch ID or their Mac password, for one Space that
/// allows the terminal; `unlock` always asks, whatever the Space's Ask to
/// authenticate says, since anything running as the person can reach the
/// commands socket.
extension TerminalPasswordsCommand {
    // MARK: - Types

    private struct PasswordRow: Encodable {
        let id: String
        let site: String
        let username: String
        let email: String?
        let category: String?
        let includesSubdomains: Bool
        let updatedAt: Date
    }

    private struct PasswordItem: Encodable {
        let id: String
        let site: String
        let username: String
        let email: String?
        let category: String?
        let includesSubdomains: Bool
        let password: String
        let notes: String?
        let updatedAt: Date
    }

    private struct SessionStatus: Encodable {
        let session: SessionDetail?
        let spacesAllowingTerminal: [String]
    }

    private struct SessionDetail: Encodable {
        let space: String
        let expiresAt: Date
    }

    private typealias Refusal = BrowserMacTerminal.Refusal

    // MARK: - Actions - Running

    @MainActor
    func run(in terminal: BrowserMacTerminal) async throws(BrowserMacTerminal.Refusal) -> TerminalOutput {
        let sessions = BrowserCredentialTerminalSessions.shared
        switch self {
        case .status(let key):
            return status(key, sessions: sessions, terminal: terminal)
        case .unlock(let name, let minutes, let raw):
            return try await unlock(
                try terminal.space(name), minutes: minutes, raw: raw, sessions: sessions, terminal: terminal)
        case .lock(let key, let all):
            if all {
                sessions.endAll()
                return TerminalOutput(text: "Ended every password session.")
            }
            guard let session = sessions.session(for: key) else { throw Refusal("This shell has no open session.") }
            sessions.end(session.id)
            return TerminalOutput(text: "Ended the session.")
        case .list(let key, let search, let site, let category):
            let space = try Self.space(for: key, sessions: sessions, terminal: terminal)
            return try await list(in: space, search: search, site: site, category: category, terminal: terminal)
        case .get(let key, let field, let item, let username):
            let space = try Self.space(for: key, sessions: sessions, terminal: terminal)
            return try await get(
                field, of: try await Self.descriptor(item, username: username, in: space, terminal: terminal),
                terminal: terminal)
        case .create(let key, let account):
            let space = try Self.space(for: key, sessions: sessions, terminal: terminal)
            return try await create(account, in: space, terminal: terminal)
        case .edit(let key, let item, let username, let changes):
            let space = try Self.space(for: key, sessions: sessions, terminal: terminal)
            let descriptor = try await Self.descriptor(item, username: username, in: space, terminal: terminal)
            return try await edit(descriptor, with: changes, in: space, terminal: terminal)
        case .delete(let key, let item, let username):
            let space = try Self.space(for: key, sessions: sessions, terminal: terminal)
            let descriptor = try await Self.descriptor(item, username: username, in: space, terminal: terminal)
            do {
                try await terminal.browser.deleteCredential(id: descriptor.id, in: descriptor.spaceID)
            } catch {
                throw Refusal("Arma couldn't delete that password.")
            }
            return TerminalOutput(text: "Deleted \(descriptor.username) on \(descriptor.origin.host).")
        case .generate(let generation):
            let space = terminal.frontWindow?.browser.shownSpace ?? terminal.browser.shownSpace
            let password = try Self.generate(generation, in: space, terminal: terminal)
            return TerminalOutput(text: password, value: ["password": password])
        }
    }

    // MARK: - Actions - Sessions

    @MainActor
    private func unlock(
        _ space: SpaceModel, minutes: Int?, raw: Bool, sessions: BrowserCredentialTerminalSessions,
        terminal: BrowserMacTerminal
    ) async throws(Refusal) -> TerminalOutput {
        let name = space.settings.name
        let space = try terminal.unlocked(space)
        let preferences = space.settings.credentialPreferences
        guard preferences.isEnabled else { throw Refusal("'\(name)' doesn't use Arma Passwords.") }
        guard preferences.allowsCommandLine else {
            throw Refusal("Turn on Settings › \(name) › Passwords › Allow command-line access first.")
        }
        let reason = String(localized: "Unlock \(name)’s passwords for the terminal.")
        guard (try? await SystemBrowserDeviceAuthenticator().authenticate(reason: reason)) == true else {
            throw Refusal("Authentication was cancelled; nothing was unlocked.")
        }
        let key = sessions.open(on: space.id, minutes: minutes)
        let length = min(
            max(minutes ?? BrowserCredentialTerminalSessions.longestMinutes, 1),
            BrowserCredentialTerminalSessions.longestMinutes)
        BrowserNoticeCenter.shared.post(
            BrowserNotice(
                message: String(localized: "Terminal unlocked \(name)’s passwords for \(length) min"),
                systemImage: "terminal"))
        return TerminalOutput(text: raw ? key : "export ARMA_SESSION=\"\(key)\"", value: ["session": key])
    }

    @MainActor
    private func status(
        _ key: String?, sessions: BrowserCredentialTerminalSessions, terminal: BrowserMacTerminal
    ) -> TerminalOutput {
        let allowing = terminal.spaces.filter {
            $0.settings.credentialPreferences.isEnabled && $0.settings.credentialPreferences.allowsCommandLine
        }.map(\.settings.name)
        let session = sessions.session(for: key)
        let detail = session.flatMap { session in
            terminal.browser.spaceModel(session.spaceID).map {
                SessionDetail(space: $0.settings.name, expiresAt: session.expiresAt)
            }
        }
        var lines: [String] = []
        if let detail {
            lines.append(
                "Unlocked: \(detail.space) until \(detail.expiresAt.formatted(date: .omitted, time: .shortened))")
        } else {
            lines.append("Locked. Run eval \"$(arma passwords unlock --space <name>)\".")
        }
        lines.append(
            allowing.isEmpty
                ? "No Space allows the terminal. Turn on Settings › Space › Passwords › Allow command-line access."
                : "Spaces that allow the terminal: \(allowing.joined(separator: ", "))")
        return TerminalOutput(
            text: lines.joined(separator: "\n"), value: SessionStatus(session: detail, spacesAllowingTerminal: allowing)
        )
    }

    /// The Space the session `key` unlocked, while it is still open and the
    /// Space still allows the terminal.
    @MainActor
    private static func space(
        for key: String?, sessions: BrowserCredentialTerminalSessions, terminal: BrowserMacTerminal
    ) throws(Refusal) -> SpaceModel {
        guard let session = sessions.session(for: key) else {
            throw Refusal(
                "No open session. Run eval \"$(arma passwords unlock --space <name>)\", or pass --session <key>.")
        }
        guard let space = terminal.browser.spaceModel(session.spaceID),
            space.settings.credentialPreferences.isEnabled, space.settings.credentialPreferences.allowsCommandLine
        else {
            sessions.end(session.id)
            throw Refusal("The session's Space no longer allows the terminal.")
        }
        return try terminal.unlocked(space)
    }

    // MARK: - Actions - Reading

    @MainActor
    private func list(
        in space: SpaceModel, search: String?, site: String?, category: String?, terminal: BrowserMacTerminal
    ) async throws(Refusal) -> TerminalOutput {
        let descriptors = try await Self.descriptors(in: space, terminal: terminal).filter { descriptor in
            (search.map { descriptor.matches(settingsQuery: $0) } ?? true)
                && (site.map { descriptor.origin.host.localizedCaseInsensitiveContains($0) } ?? true)
                && (category.map { descriptor.category?.caseInsensitiveCompare($0) == .orderedSame } ?? true)
        }
        let rows = descriptors.map { descriptor in
            PasswordRow(
                id: descriptor.id.uuidString.lowercased(), site: Self.site(of: descriptor),
                username: descriptor.username, email: descriptor.email, category: descriptor.category,
                includesSubdomains: descriptor.includesSubdomains, updatedAt: descriptor.updatedAt)
        }
        let text =
            rows.isEmpty
            ? "No saved passwords."
            : rows.map { row in
                [String(row.id.prefix(8)), row.site, row.username, row.category.map { "[\($0)]" }]
                    .compactMap { $0 }.joined(separator: "  ")
            }.joined(separator: "\n")
        return TerminalOutput(text: text, value: rows)
    }

    @MainActor
    private func get(
        _ field: TerminalPasswordField, of descriptor: CredentialDescriptor, terminal: BrowserMacTerminal
    ) async throws(Refusal) -> TerminalOutput {
        switch field {
        case .username:
            return TerminalOutput(text: descriptor.username, value: ["username": descriptor.username])
        case .email:
            guard let email = descriptor.email else { throw Refusal("That password has no email.") }
            return TerminalOutput(text: email, value: ["email": email])
        case .password, .notes, .item:
            let credential: BrowserCredential?
            let notes: String?
            do {
                credential = try await terminal.browser.credential(id: descriptor.id, in: descriptor.spaceID)
                notes = try await terminal.browser.credentialNotes(for: descriptor)
            } catch {
                throw Refusal("Arma couldn't read that password.")
            }
            guard let credential else { throw Refusal("That password is no longer saved.") }
            switch field {
            case .password:
                return TerminalOutput(text: credential.password, value: ["password": credential.password])
            case .notes:
                guard let notes else { throw Refusal("That password has no notes.") }
                return TerminalOutput(text: notes, value: ["notes": notes])
            default:
                let item = PasswordItem(
                    id: descriptor.id.uuidString.lowercased(), site: Self.site(of: descriptor),
                    username: descriptor.username, email: descriptor.email, category: descriptor.category,
                    includesSubdomains: descriptor.includesSubdomains, password: credential.password, notes: notes,
                    updatedAt: descriptor.updatedAt)
                let text = [
                    "site: \(item.site)", "username: \(item.username)", item.email.map { "email: \($0)" },
                    item.category.map { "category: \($0)" }, "password: \(item.password)",
                    item.notes.map { "notes:\n\($0)" },
                ].compactMap { $0 }.joined(separator: "\n")
                return TerminalOutput(text: text, value: item)
            }
        }
    }

    // MARK: - Actions - Writing

    @MainActor
    private func create(
        _ account: TerminalPasswordAccount, in space: SpaceModel, terminal: BrowserMacTerminal
    ) async throws(Refusal) -> TerminalOutput {
        guard let site = account.site, let address = Self.address(site) else {
            throw Refusal("Give a website, such as example.com.")
        }
        guard let username = account.username, !username.isEmpty else { throw Refusal("Give --username.") }
        let password = try Self.password(account.password, in: space, terminal: terminal)
        do {
            let descriptor = try await terminal.browser.saveCredential(
                username: username, password: password, for: address, in: space.id, email: account.email ?? "",
                category: account.category ?? "", includesSubdomains: account.includesSubdomains ?? false)
            if let notes = account.notes { try await terminal.browser.setCredentialNotes(notes, for: descriptor) }
            let id = descriptor.id.uuidString.lowercased()
            return TerminalOutput(
                text: "Saved \(username) on \(descriptor.origin.host) (\(id.prefix(8))).", value: ["id": id])
        } catch let rejection as Rejection {
            throw Refusal(rejection.explanation)
        } catch CredentialVaultError.insecureOrigin {
            throw Refusal("Arma saves passwords only for https websites.")
        } catch CredentialVaultError.notesTooLong {
            throw Refusal("Notes hold up to \(credentialNotesByteLimit) bytes.")
        } catch {
            throw Refusal("Arma couldn't save that password.")
        }
    }

    @MainActor
    private func edit(
        _ descriptor: CredentialDescriptor, with changes: TerminalPasswordAccount, in space: SpaceModel,
        terminal: BrowserMacTerminal
    ) async throws(Refusal) -> TerminalOutput {
        let current: BrowserCredential?
        do {
            current = try await terminal.browser.credential(id: descriptor.id, in: descriptor.spaceID)
        } catch {
            throw Refusal("Arma couldn't read that password.")
        }
        guard let current, let address = URL(string: descriptor.origin.description) else {
            throw Refusal("That password is no longer saved.")
        }
        var password = current.password
        if let source = changes.password { password = try Self.password(source, in: space, terminal: terminal) }
        do {
            let saved = try await terminal.browser.saveCredential(
                username: changes.username ?? descriptor.username, password: password,
                for: address, in: descriptor.spaceID, replacing: descriptor, email: changes.email,
                category: changes.category, includesSubdomains: changes.includesSubdomains)
            if let notes = changes.notes { try await terminal.browser.setCredentialNotes(notes, for: saved) }
            return TerminalOutput(text: "Changed \(saved.username) on \(saved.origin.host).")
        } catch let rejection as Rejection {
            throw Refusal(rejection.explanation)
        } catch CredentialVaultError.notesTooLong {
            throw Refusal("Notes hold up to \(credentialNotesByteLimit) bytes.")
        } catch {
            throw Refusal("Arma couldn't change that password.")
        }
    }

    // MARK: - Actions - Finding

    @MainActor
    private static func descriptors(
        in space: SpaceModel, terminal: BrowserMacTerminal
    ) async throws(Refusal) -> [CredentialDescriptor] {
        do {
            return try await terminal.browser.savedCredentialDescriptors(in: space.id)
                .sorted { ($0.origin.host, $0.username) < ($1.origin.host, $1.username) }
        } catch {
            throw Refusal("Arma couldn't read this Space's passwords.")
        }
    }

    /// The saved password `reference` names: its site, or the start of its
    /// id, at least 4 characters, narrowed by `username` where the site has
    /// several.
    @MainActor
    private static func descriptor(
        _ reference: String, username: String?, in space: SpaceModel, terminal: BrowserMacTerminal
    ) async throws(Refusal) -> CredentialDescriptor {
        let all = try await descriptors(in: space, terminal: terminal)
        let wanted = reference.trimmingCharacters(in: .whitespaces).lowercased()
        let host = address(wanted)?.host() ?? wanted
        var matches = all.filter { $0.origin.host == host }
        if matches.isEmpty, wanted.count >= 4 {
            matches = all.filter { $0.id.uuidString.lowercased().hasPrefix(wanted) }
        }
        if let username {
            matches = matches.filter { $0.username.caseInsensitiveCompare(username) == .orderedSame }
        }
        switch matches.count {
        case 1:
            return matches[0]
        case 0:
            throw Refusal("No saved password matches '\(reference)'. Run arma passwords list.")
        default:
            let choices = matches.map { "\($0.id.uuidString.lowercased().prefix(8))  \($0.username)" }
            throw Refusal(
                "'\(reference)' has \(matches.count) passwords; give --username or an id:\n"
                    + choices.joined(separator: "\n"))
        }
    }

    // MARK: - Actions - Passwords

    /// The password `source` gives: the one read from standard input, or one
    /// the Space's generator makes.
    @MainActor
    private static func password(
        _ source: TerminalPasswordSource?, in space: SpaceModel, terminal: BrowserMacTerminal
    ) throws(Refusal) -> String {
        switch source {
        case .given(let password): return password
        case .generated(let generation): return try generate(generation, in: space, terminal: terminal)
        case nil: throw Refusal("Give --password-stdin or --generate.")
        }
    }

    @MainActor
    private static func generate(
        _ requested: TerminalPasswordGeneration, in space: SpaceModel?, terminal: BrowserMacTerminal
    ) throws(Refusal) -> String {
        var generation = space?.settings.credentialPreferences.generation ?? .standard
        if let length = requested.length { generation.length = length }
        if let lowercase = requested.lowercase { generation.lowercase = lowercase }
        if let uppercase = requested.uppercase { generation.uppercase = uppercase }
        if let numbers = requested.numbers { generation.numbers = numbers }
        if let symbols = requested.symbols { generation.symbols = symbols }
        guard generation.lowercase || generation.uppercase || generation.numbers || generation.symbols else {
            throw Refusal("Keep at least one kind of character.")
        }
        do {
            return try BrowserStrongPasswordGenerator.generate(from: terminal.browser.strongPasswordRecipe(generation))
        } catch {
            throw Refusal(
                "A password is \(PasswordGeneration.minimumLength) to \(PasswordGeneration.maximumLength) characters.")
        }
    }

    // MARK: - Actions - Spelling

    private static func site(of descriptor: CredentialDescriptor) -> String {
        descriptor.includesSubdomains ? "*.\(descriptor.origin.host)" : descriptor.origin.host
    }

    /// `text` as an address: as given when it names a scheme, otherwise its
    /// https address.
    private static func address(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let url = URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
        return url?.host() == nil ? nil : url
    }
}
