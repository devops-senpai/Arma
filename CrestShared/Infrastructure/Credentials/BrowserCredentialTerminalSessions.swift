import CryptoKit
import Foundation
import Observation

// MARK: - Types

/// One Space unlocked for `arma passwords`, as Settings lists it. The key
/// itself is never kept: only its digest, so nothing Arma holds can be
/// replayed as one.
struct BrowserCredentialTerminalSession: Identifiable, Equatable, Sendable {
    let id: UUID
    let spaceID: UUID
    let startedAt: Date
    let expiresAt: Date
    fileprivate let digest: Data
}

/// The Spaces the person unlocked for `arma passwords`, each with a session
/// key the terminal carries. A session reaches one Space and lasts an hour at
/// most; it ends sooner when the person locks it, ends every session, or the
/// Mac sleeps or locks, and with the process, since sessions live in memory
/// alone.
@Observable
@MainActor
final class BrowserCredentialTerminalSessions {
    // MARK: - Static Variables

    static let shared = BrowserCredentialTerminalSessions()

    /// The longest a session lasts, and how long one lasts unless the person
    /// asks for less.
    static let longestMinutes = 60

    // MARK: - Variables

    private(set) var sessions: [BrowserCredentialTerminalSession] = []
    @ObservationIgnored private var expiries: [UUID: Task<Void, Never>] = [:]

    // MARK: - Initializers

    init() {}

    // MARK: - Actions - Opening

    /// Opens a session on Space `spaceID` for `minutes`, an hour at most,
    /// and answers its key, drawn from the system's secure random source,
    /// which is shown once and kept nowhere.
    func open(on spaceID: UUID, minutes: Int?, now: Date = .now) -> String {
        let length = min(max(minutes ?? Self.longestMinutes, 1), Self.longestMinutes)
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        let key = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let session = BrowserCredentialTerminalSession(
            id: UUID(), spaceID: spaceID, startedAt: now, expiresAt: now.addingTimeInterval(TimeInterval(length * 60)),
            digest: Self.digest(key))
        sessions.append(session)
        expiries[session.id] = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(TimeInterval(length * 60)))
            guard !Task.isCancelled else { return }
            self?.end(session.id)
        }
        return key
    }

    // MARK: - Actions - Reading

    /// The open session `key` names, or nil for a key that names none, has
    /// ended or has run out.
    func session(for key: String?, now: Date = .now) -> BrowserCredentialTerminalSession? {
        guard let key, !key.isEmpty else { return nil }
        let digest = Self.digest(key)
        return sessions.first { $0.digest == digest && $0.expiresAt > now }
    }

    // MARK: - Mutators

    /// Ends session `id`.
    func end(_ id: UUID) {
        expiries.removeValue(forKey: id)?.cancel()
        sessions.removeAll { $0.id == id }
    }

    /// Ends every session, as the Mac sleeping or locking does.
    func endAll() {
        for task in expiries.values { task.cancel() }
        expiries.removeAll()
        sessions.removeAll()
    }

    /// Ends every session on Space `spaceID`, as turning off its command-line
    /// access does.
    func endAll(on spaceID: UUID) {
        for session in sessions where session.spaceID == spaceID { end(session.id) }
    }

    private static func digest(_ key: String) -> Data {
        Data(SHA256.hash(data: Data(key.utf8)))
    }
}
