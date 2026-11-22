import Foundation

/// When the person last authenticated to show or copy each Space's saved
/// passwords, so a Space that asks only every so often can let a show or copy
/// through. It lives in memory alone: quitting forgets it, and so does the
/// device sleeping, its screen locking, or another user taking it over, which
/// each platform announces as `Notification.Name.browserDeviceLocked`.
@MainActor
final class BrowserCredentialAuthenticationMemory {
    // MARK: - Variables

    private var lastAuthenticated: [UUID: Date] = [:]
    private var observer: NSObjectProtocol?

    // MARK: - Initializers

    init() {
        observer = NotificationCenter.default.addObserver(forName: .browserDeviceLocked, object: nil, queue: .main) {
            [weak self] _ in
            Task { @MainActor [weak self] in self?.forgetAll() }
        }
    }

    // MARK: - Actions - Memory

    /// How many seconds ago the person last authenticated for Space
    /// `spaceID`, or nil when they have not since it was forgotten.
    func secondsSinceAuthenticated(in spaceID: UUID, at now: Date = .now) -> Double? {
        lastAuthenticated[spaceID].map { now.timeIntervalSince($0) }
    }

    /// The person just authenticated for Space `spaceID`.
    func authenticated(in spaceID: UUID, at now: Date = .now) {
        lastAuthenticated[spaceID] = now
    }

    /// Forgets every Space's authentication, so the next show or copy asks.
    func forgetAll() {
        lastAuthenticated.removeAll()
    }
}

extension Notification.Name {
    /// The device slept, its screen locked, or another user took it over, as
    /// each platform's app announces it, so what a person unlocked in memory
    /// is forgotten.
    static let browserDeviceLocked = Notification.Name("BrowserDeviceLocked")
}
