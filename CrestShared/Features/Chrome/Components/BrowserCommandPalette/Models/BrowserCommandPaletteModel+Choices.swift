import Foundation

extension BrowserCommandPaletteModel {
    /// Shows the choices a choice just stepped into, from an empty field.
    func steppedIntoChoice() {
        narrowed()
    }

    /// Asks again for what a tool scope offers, once something it waited on
    /// arrives, such as a Space's saved logins read in the background, as
    /// `Notification.Name.browserPaletteChoicesChanged` says.
    func choicesChanged() {
        guard activeScope != nil else { return }
        requestAnswer()
    }
}

extension Notification.Name {
    /// What a tool scope offers changed after the palette asked, such as a
    /// Space's saved logins arriving from the Keychain, so an open palette
    /// asks again.
    static let browserPaletteChoicesChanged = Notification.Name("BrowserPaletteChoicesChanged")
}
