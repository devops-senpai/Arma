import AppKit

extension BrowserRootModel {
    /// Follows whether the chrome holds the floating sidebar out: while it
    /// does, a press of the mouse anywhere but over the sidebar puts it away.
    func floatingSidebarHoldChanged(reduceMotion: Bool) {
        if let floatingSidebarHoldMonitor {
            NSEvent.removeMonitor(floatingSidebarHoldMonitor)
            self.floatingSidebarHoldMonitor = nil
        }
        guard chrome.holdsFloatingSidebar else { return }
        floatingSidebarHoldMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, !self.isSidebarSurfaceHovered else { return }
                self.chrome.holdsFloatingSidebar = false
                self.dismissFloatingSidebar(reduceMotion: reduceMotion)
            }
            return event
        }
    }
}
