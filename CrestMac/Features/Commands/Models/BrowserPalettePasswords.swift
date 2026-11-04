import Foundation

/// What the command palette's @passwords scope knows in one window: the
/// saved logins of the Space it last listed, read from the vault in the
/// background, and the login a person stepped into. It holds each login's
/// site and username only, never a password.
@MainActor
final class BrowserPalettePasswords {
    // MARK: - Static Variables

    /// How long a listed Space's logins stand before the palette reads them
    /// again, so one added or removed elsewhere shows on the next look.
    private static let freshness: TimeInterval = 5

    // MARK: - Variables

    /// The login a person stepped into, whose username, password and site
    /// the palette offers.
    private(set) var steppedInto: UUID?
    private var listedSpaceID: UUID?
    private var listed: [CredentialDescriptor] = []
    private var listedAt: Date?
    private var readingSpaceID: UUID?

    // MARK: - Actions - Logins

    /// The saved logins of Space `spaceID`, as last read, or nil until the
    /// first read arrives; reads them again in the background once they are
    /// stale, and asks an open palette to look again when they arrive.
    func logins(in spaceID: UUID, from browser: BrowserStore, now: Date = .now) -> [CredentialDescriptor]? {
        let isListed = listedSpaceID == spaceID
        if !isListed || listedAt.map({ now.timeIntervalSince($0) > Self.freshness }) ?? true {
            read(spaceID, from: browser)
        }
        return isListed ? listed : nil
    }

    private func read(_ spaceID: UUID, from browser: BrowserStore) {
        guard readingSpaceID != spaceID else { return }
        readingSpaceID = spaceID
        Task { @MainActor [weak self, weak browser] in
            let logins = (try? await browser?.savedCredentialDescriptors(in: spaceID)) ?? []
            guard let self, readingSpaceID == spaceID else { return }
            readingSpaceID = nil
            listedSpaceID = spaceID
            listed = logins.sorted { ($0.origin.host, $0.username) < ($1.origin.host, $1.username) }
            listedAt = .now
            NotificationCenter.default.post(name: .browserPaletteChoicesChanged, object: nil)
        }
    }

    /// The login `id` of the listed Space, while it is still listed.
    func login(_ id: UUID) -> CredentialDescriptor? {
        listed.first { $0.id == id }
    }

    // MARK: - Mutators

    /// Steps into the login `id`, whose username, password and site the
    /// palette shows next.
    func stepInto(_ id: UUID) {
        steppedInto = id
    }

    /// Steps back out of the login the palette shows, answering whether it
    /// showed one.
    func stepBack() -> Bool {
        guard steppedInto != nil else { return false }
        steppedInto = nil
        return true
    }

    /// Forgets the login stepped into, as the palette closes.
    func reset() {
        steppedInto = nil
    }
}
