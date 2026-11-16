import Foundation

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// When the person last authenticated to show or copy each Space's saved
/// passwords, so a Space that asks only every so often can let a show or copy
/// through. It lives in memory alone: quitting forgets it, and so does the
/// device sleeping, its screen locking, or another user taking it over.
@MainActor
final class BrowserCredentialAuthenticationMemory {
    // MARK: - Static Variables

    static let shared = BrowserCredentialAuthenticationMemory()

    // MARK: - Variables

    private var lastAuthenticated: [UUID: Date] = [:]
    private var observers: [NSObjectProtocol] = []

    // MARK: - Initializers

    init() {
        observeForgetting()
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

    private func observeForgetting() {
        let forget: @Sendable (Notification) -> Void = { [weak self] _ in
            Task { @MainActor [weak self] in self?.forgetAll() }
        }
        #if os(macOS)
            let workspace = NSWorkspace.shared.notificationCenter
            for name in [
                NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                NSWorkspace.sessionDidResignActiveNotification,
            ] {
                observers.append(workspace.addObserver(forName: name, object: nil, queue: .main, using: forget))
            }
            observers.append(
                DistributedNotificationCenter.default().addObserver(
                    forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: .main, using: forget))
        #else
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main,
                    using: forget))
        #endif
    }
}
