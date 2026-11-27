import Foundation

extension BrowserCredentialPageState {
    /// Whether `descriptor`'s password may fill a page at `origin`, as the
    /// vault chose it: saved for that origin, or for one the core reads as
    /// it, on the site it was saved for or any the person added to it. The
    /// vault suggests a login on each of its sites, so checking only the one
    /// it was saved for refused to fill the rest. A core that refuses fills
    /// nothing.
    func fills(_ origin: CredentialOrigin, with descriptor: CredentialDescriptor) -> Bool {
        if descriptor.origins.contains(origin) { return true }
        return (try? core.fills(origin, from: descriptor.origins))?.contains(true) ?? false
    }
}
