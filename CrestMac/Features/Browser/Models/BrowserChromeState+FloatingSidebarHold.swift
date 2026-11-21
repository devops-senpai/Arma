import Foundation

extension BrowserChromeState {
    /// Rolls a hidden sidebar out over the page until the person clicks
    /// outside it, so what a command shows there, such as the software update
    /// card, can be read. A docked sidebar already shows it.
    func floatSidebarUntilClickElsewhere() {
        guard columnVisibility == .detailOnly else { return }
        isFloatingSidebarPresented = true
        holdsFloatingSidebar = true
    }
}
