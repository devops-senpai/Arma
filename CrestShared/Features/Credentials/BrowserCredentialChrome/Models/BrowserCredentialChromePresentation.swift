import Foundation

enum BrowserCredentialChromePresentation: Equatable {
    case none
    case save(BrowserCredentialSaveCandidate)
    case strongPassword(BrowserCredentialFillRequest)
    case suggestions(BrowserCredentialFillRequest)
    case codes(BrowserCredentialFillRequest)
    case autofill(BrowserCredentialFillRequest)
    case saveAutofill(BrowserAutofillSaveCandidate)
    /// The offer to pause the prompts on the page, after the person closed
    /// one, which shows only while no other prompt does.
    case pauseOffer(UUID)

    static func resolve(
        saveCandidate: BrowserCredentialSaveCandidate?,
        fillRequest: BrowserCredentialFillRequest?,
        autofillSaveCandidate: BrowserAutofillSaveCandidate? = nil,
        pauseOffer: UUID? = nil
    ) -> BrowserCredentialChromePresentation {
        if let saveCandidate {
            return .save(saveCandidate)
        }
        if let autofillSaveCandidate {
            return .saveAutofill(autofillSaveCandidate)
        }
        guard let fillRequest else { return pauseOffer.map(Self.pauseOffer) ?? .none }
        if fillRequest.codeFields != nil { return .codes(fillRequest) }
        if fillRequest.autofill != nil { return .autofill(fillRequest) }
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
        case .none, .save, .saveAutofill, .pauseOffer:
            nil
        case .strongPassword(let request), .suggestions(let request), .codes(let request), .autofill(let request):
            request
        }
    }
}
