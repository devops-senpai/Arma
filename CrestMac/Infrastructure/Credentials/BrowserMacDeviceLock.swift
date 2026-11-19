import AppKit

/// Announces `Notification.Name.browserDeviceLocked` when the Mac sleeps, its
/// screens sleep, it locks, or another user takes it over.
enum BrowserMacDeviceLock {
    // MARK: - Actions - Announcing

    static func announce() {
        let post: @Sendable (Notification) -> Void = { _ in
            NotificationCenter.default.post(name: .browserDeviceLocked, object: nil)
        }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification,
        ] {
            workspace.addObserver(forName: name, object: nil, queue: .main, using: post)
        }
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: .main, using: post)
    }
}
