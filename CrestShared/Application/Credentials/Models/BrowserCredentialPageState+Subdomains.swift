import Foundation

extension BrowserCredentialPageState {
    /// Whether `descriptor`'s password may fill a page at `origin`: saved for
    /// it, or reaching it from the site above. A core that refuses fills
    /// nothing.
    func fills(_ origin: CredentialOrigin, with descriptor: CredentialDescriptor) -> Bool {
        if descriptor.origin == origin { return true }
        let reaching = descriptor.includesSubdomains ? [0] : []
        return (try? core.fills(origin, from: [descriptor.origin], reaching: reaching))?.first ?? false
    }
}
