import SwiftUI

/// While the save prompt asks, the person can correct what it keeps and tell
/// the Space never to save on the site; it closes from the ✕ at its corner, or
/// on its own after the Space's time while it only asks, held while the pointer
/// rests on it and once the person starts answering.
extension BrowserCredentialSavePrompt {
    /// What a save would keep now.
    var current: BrowserCredentialSaveCandidate {
        draft ?? candidate
    }

    /// What the person may change before saving, which changes what a save
    /// means: a new account, an update, or nothing to do.
    struct Correction: Hashable {
        let username: String
        let password: String
    }

    var correction: Correction? {
        guard isEngaged, let draft else { return nil }
        return Correction(username: draft.username, password: draft.password)
    }

    /// The fields, while the prompt asks and nothing is being saved.
    var fields: BrowserCredentialSaveFields? {
        guard draft != nil, model.asksForAnswer else { return nil }
        return BrowserCredentialSaveFields(
            email: draftBinding(\.email),
            username: draftBinding(\.username),
            password: draftBinding(\.password),
            category: draftBinding(\.category),
            notes: draftBinding(\.notes),
            includesSubdomains: draftBinding(\.includesSubdomains),
            categories: categories,
            offersSubdomains: offersSubdomains,
            isEditable: !model.isSaving,
            engage: { isEngaged = true }
        )
    }

    func draftBinding<Value>(
        _ keyPath: WritableKeyPath<BrowserCredentialSaveCandidate, Value>
    ) -> Binding<Value> {
        Binding(
            get: { current[keyPath: keyPath] },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    /// Starts asking about a new candidate: its subdomains included where the
    /// site allows it, as the person most often wants.
    func begin() {
        offersSubdomains = browser.allowsSubdomainReach(from: candidate.origin)
        var fresh = candidate
        fresh.includesSubdomains = offersSubdomains
        // A username that is an email address is the account's email too.
        if fresh.username.contains("@") { fresh.email = fresh.username }
        draft = fresh
        isEngaged = false
    }

    /// Plans the save again once the person stops typing, so the prompt says
    /// whether it saves a new account or updates one already kept.
    func replanAfterCorrection() async {
        guard correction != nil else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, model.asksForAnswer else { return }
        await prepare(dismissesWhenStored: false)
    }

    /// What restarts the prompt's countdown: another candidate, the pointer
    /// arriving or leaving, or the prompt starting or stopping asking.
    struct Countdown: Hashable {
        let candidateID: UUID
        let isPointerResting: Bool
        let closes: Bool
    }

    var countdown: Countdown {
        Countdown(
            candidateID: candidate.id, isPointerResting: isPointerResting, closes: model.closesOnItsOwn && !isEngaged)
    }

    /// Never for This Site, offered only while the prompt asks.
    var neverSaveAction: (() -> Void)? {
        guard model.asksForAnswer else { return nil }
        return { neverSaveOnSite() }
    }

    /// The ✕ at the prompt's corner, which puts it away as Not Now does.
    var closeButton: some View {
        Button(action: port.close ?? port.dismiss) {
            Image(systemName: "xmark")
                .font(.system(size: BrowserCredentialPromptMetrics.closeGlyphSize, weight: .bold))
        }
        .buttonStyle(
            CrestChromeButtonStyle(
                controlSize: CGSize(
                    width: BrowserCredentialPromptMetrics.closeButtonSize,
                    height: BrowserCredentialPromptMetrics.closeButtonSize),
                cornerRadius: BrowserCredentialPromptMetrics.closeButtonSize / 2, showsRestingFill: true)
        )
        .offset(
            x: -BrowserCredentialPromptMetrics.closeButtonInset, y: -BrowserCredentialPromptMetrics.closeButtonInset
        )
        .disabled(model.isBusy)
        .accessibilityLabel(Text("Close"))
        .accessibilityIdentifier("crest-password-save-close")
    }

    /// Puts the prompt away once its time is up, as long as it is only
    /// asking: the Space's time from when it starts asking, starting over
    /// whenever the pointer leaves it, since the pointer often crosses the
    /// corner it sits in. Never while the pointer rests on it, the person is
    /// answering it, a save is under way or something failed.
    func closeWhenTimeIsUp() async {
        guard model.closesOnItsOwn, !isEngaged, !isPointerResting else { return }
        let wait: Duration = .seconds(preferences.savePromptSeconds)
        try? await Task.sleep(for: wait)
        guard !Task.isCancelled, model.closesOnItsOwn, !isEngaged, !isPointerResting,
            port.presentedCandidateID() == candidate.id
        else { return }
        port.dismiss()
    }

    /// Stops this Space offering to save on the page's site, and everything
    /// under it when the person keeps Include subdomains, then puts the prompt
    /// away. A site whose subdomains belong to others is kept alone. Saved
    /// passwords still fill there.
    func neverSaveOnSite() {
        let host = candidate.topLevelOrigin.host
        do {
            try browser.neverSaveSite(host, includesSubdomains: current.includesSubdomains, in: port.spaceID)
        } catch {
            try? browser.neverSaveSite(host, includesSubdomains: false, in: port.spaceID)
        }
        port.dismiss()
    }
}
