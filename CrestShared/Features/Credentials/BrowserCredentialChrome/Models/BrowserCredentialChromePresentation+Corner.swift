import Foundation

extension BrowserCredentialChromePresentation {
    /// Whether this floats at the page's corner like a notification: the
    /// offer to save a submitted password.
    var floatsAtCorner: Bool {
        switch self {
        case .save: true
        case .none, .strongPassword, .suggestions: false
        }
    }
}
