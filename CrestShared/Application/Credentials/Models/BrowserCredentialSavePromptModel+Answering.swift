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

    /// Whether the prompt still waits for the person's answer: planning it,
    /// asking to save or update, or after a plan that failed. Never once a
    /// save is under way or done.
    var asksForAnswer: Bool {
        guard systemPasswordOfferPhase == .notRequested else { return false }
        return switch phase {
        case .preparing, .create, .update, .failed(.preparation): true
        case .alreadyStored, .saving, .saved, .failed(.commit): false
        }
    }

    /// Whether a save is under way.
    var isSaving: Bool {
        if case .saving = phase { return true }
        return false
    }
}
