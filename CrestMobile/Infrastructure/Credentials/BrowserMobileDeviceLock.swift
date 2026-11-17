import UIKit

/// Announces `Notification.Name.browserDeviceLocked` when the device locks
/// and its protected data becomes unavailable.
enum BrowserMobileDeviceLock {
    // MARK: - Actions - Announcing

    static func announce() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .browserDeviceLocked, object: nil)
        }
    }
}
