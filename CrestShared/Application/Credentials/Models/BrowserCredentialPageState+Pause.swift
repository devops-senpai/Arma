import Foundation

/// Pausing Arma's password prompts on one page, for a page another password
/// manager should fill: no fill offers, no saves and nothing captured until
/// the person resumes them or the pause's time runs out. Closing a prompt
/// keeps every prompt away for a moment and offers the pause.
extension BrowserCredentialPageState {
    /// How long the prompts stay away after the person closes one, so the
    /// field they return to doesn't raise it again at once.
    static var snoozeDuration: TimeInterval { 3 }

    /// Closes the prompt the person closed, keeps every prompt away for
    /// `snoozeDuration`, and offers to pause them on this page. A shown offer
    /// to save is held for the address field's key, as Not Now holds it.
    func snooze(now: Date = .now) {
        snoozedUntil = now.addingTimeInterval(Self.snoozeDuration)
        dismissFillRequest()
        if saveCandidate != nil { holdSaveCandidate() }
        if !isPaused { pauseOffer = UUID() }
    }

    func dismissPauseOffer() {
        pauseOffer = nil
    }

    /// Pauses the prompts on this page for `length`, after which they come
    /// back on their own unless the person resumes them sooner.
    func pause(for length: BrowserCredentialPauseLength, now: Date = .now) {
        isPaused = true
        pauseOffer = nil
        pausedUntil = length.end(from: now)
        dismissFillRequest()
        dismissSaveCandidate()
        pauseExpiry?.cancel()
        guard let seconds = length.seconds else {
            pauseExpiry = nil
            return
        }
        pauseExpiry = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.resume()
        }
    }

    /// Resumes the prompts on this page.
    func resume() {
        pauseExpiry?.cancel()
        pauseExpiry = nil
        isPaused = false
        pausedUntil = nil
    }

    /// Whether a prompt may appear now: not while paused or snoozed.
    func offersPrompts(at now: Date) -> Bool {
        !isPaused && (snoozedUntil.map { now >= $0 } ?? true)
    }
}
