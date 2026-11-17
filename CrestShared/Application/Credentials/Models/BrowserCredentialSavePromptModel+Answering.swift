import Foundation

extension BrowserCredentialSavePromptModel {
    /// Whether the prompt is only asking, with nothing under way and nothing
    /// gone wrong: the one time it may close on its own once its time is up.
    var closesOnItsOwn: Bool {
        guard systemPasswordOfferPhase == .notRequested else { return false }
        return switch phase {
        case .create, .update:
            true
        case .preparing, .alreadyStored, .saving, .saved, .failed:
            false
        }
    }
}
