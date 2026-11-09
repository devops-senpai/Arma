import Foundation

/// `arma passwords`: one Space's saved passwords from the terminal, after the
/// person unlocks the Space for it with Touch ID or their Mac password.
///
/// `unlock` answers a session key, which the commands after it carry, read
/// from `ARMA_SESSION` or `--session`. A session reaches one Space, lasts an
/// hour at most and ends sooner with `lock`, when Arma quits, or when the Mac
/// sleeps or locks. `generate` needs no session.
enum TerminalPasswordsCommand: Codable, Sendable {
    /// Which Spaces allow the terminal, and whether `session` is still open.
    case status(session: String?)
    /// Unlocks `space` for the terminal for `minutes`, an hour unless fewer;
    /// answers the key alone with `raw`, or a line for the shell to export.
    case unlock(space: String?, minutes: Int?, raw: Bool)
    /// Ends `session`, or every session with `all`.
    case lock(session: String?, all: Bool)
    /// The session's saved passwords, without their secrets, narrowed by
    /// `search`, `site` and `category`.
    case list(session: String?, search: String?, site: String?, category: String?)
    /// One field of the saved password `item` names, by site or id, or the
    /// whole of it; `username` picks among a site's accounts.
    case get(session: String?, field: TerminalPasswordField, item: String, username: String?)
    /// Saves a new password for `site`.
    case create(session: String?, account: TerminalPasswordAccount)
    /// Changes the saved password `item` names; a nil field stays as it is.
    case edit(session: String?, item: String, username: String?, changes: TerminalPasswordAccount)
    /// Deletes the saved password `item` names.
    case delete(session: String?, item: String, username: String?)
    /// A new password made to `generation`, saved nowhere.
    case generate(generation: TerminalPasswordGeneration)
}

/// One field of a saved password `arma passwords get` prints.
enum TerminalPasswordField: String, Codable, Sendable, CaseIterable {
    case password
    case username
    case email
    case notes
    case item
}

/// What `create` saves, or what `edit` changes; for `edit` a nil field stays
/// as it is.
struct TerminalPasswordAccount: Codable, Sendable {
    var site: String?
    var username: String?
    var email: String?
    var category: String?
    var includesSubdomains: Bool?
    /// The password, as read from standard input or generated.
    var password: TerminalPasswordSource?
    /// The notes, as read from a file.
    var notes: String?
}

/// Where a password `create` or `edit` saves comes from.
enum TerminalPasswordSource: Codable, Sendable {
    /// Read from standard input, never from the command's words.
    case given(String)
    /// Made by the Space's generator, with these changes.
    case generated(TerminalPasswordGeneration)
}

/// How `generate`, and a generated password, is made: the Space's generator,
/// where a field is nil, and these where they say otherwise.
struct TerminalPasswordGeneration: Codable, Sendable {
    var length: Int?
    var lowercase: Bool?
    var uppercase: Bool?
    var numbers: Bool?
    var symbols: Bool?
}
