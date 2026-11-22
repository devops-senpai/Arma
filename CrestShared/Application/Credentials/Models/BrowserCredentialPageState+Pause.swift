import Foundation

extension BrowserCredentialPageState {
    /// How long the prompts stay away after the person closes one.
    static var snoozeDuration: TimeInterval { 3 }

    /// Closes the prompt the person closed, keeps every prompt away for
    /// `snoozeDuration`, so the field they return to doesn't raise it again
    /// at once, and offers to pause them on this page.
    func snooze(now: Date = .now) {
        snoozedUntil = now.addingTimeInterval(Self.snoozeDuration)
        dismissFillRequest()
        dismissSaveCandidate()
        if !isPaused { pauseOffer = UUID() }
    }

    func dismissPauseOffer() {
        pauseOffer = nil
    }

    /// Pauses Arma's password prompts on this page for `length`, after which
    /// they come back on their own unless the person resumes them sooner.
    func pause(for length: BrowserCredentialPauseLength, now: Date = .now) {
        isPaused = true
        pauseOffer = nil
        pausedUntil = length.end(from: now)
        dismissFillRequest()
        dismissSaveCandidate()
        pauseExpiry?.cancel()
        guard let seconds = length.seconds else { return }
        pauseExpiry = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.resume()
        }
    }

    /// Resumes Arma's password prompts on this page.
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
