import Foundation

enum BrowserCredentialChromePresentation: Equatable {
    case none
    case save(BrowserCredentialSaveCandidate)
    case strongPassword(BrowserCredentialFillRequest)
    case suggestions(BrowserCredentialFillRequest)
    /// The offer to pause password prompts on this tab, after the person
    /// closed one.
    case pauseOffer(UUID)

    static func resolve(
        saveCandidate: BrowserCredentialSaveCandidate?,
        fillRequest: BrowserCredentialFillRequest?,
        pauseOffer: UUID? = nil
    ) -> BrowserCredentialChromePresentation {
        if let saveCandidate {
            return .save(saveCandidate)
        }
        guard let fillRequest else { return pauseOffer.map(BrowserCredentialChromePresentation.pauseOffer) ?? .none }
        switch fillRequest.passwordKind {
        case .current:
            return .suggestions(fillRequest)
        case .new:
            return .strongPassword(fillRequest)
        }
    }

    /// The field request behind this prompt, where there is one. A save prompt
    /// answers a form that has already been submitted, so it has no field left
    /// to point at.
    var fillRequest: BrowserCredentialFillRequest? {
        switch self {
        case .none, .save, .pauseOffer:
            nil
        case .strongPassword(let request), .suggestions(let request):
            request
        }
    }

    /// Whether this floats at the page's corner like a notification: the
    /// offer to save a submitted password, or to pause the prompts.
    var floatsAtCorner: Bool {
        switch self {
        case .save, .pauseOffer: true
        case .none, .strongPassword, .suggestions: false
        }
    }
}
