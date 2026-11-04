import SwiftUI

/// The offer to keep the password a form was just submitted with.
///
/// Everything the prompt needs from the page arrives through
/// `BrowserCredentialSavePort`, every word it says comes from
/// `BrowserCredentialPromptRoute`, and everything about how it is drawn comes
/// from `BrowserCredentialPromptMetrics`. So both shells share this prompt
/// rather than a resemblance.
struct BrowserCredentialSavePrompt: View {
    let candidate: BrowserCredentialSaveCandidate
    let port: BrowserCredentialSavePort
    let browser: BrowserStore
    let metrics: BrowserCredentialPromptMetrics

    @State private var model = BrowserCredentialSavePromptModel()
    /// Whether the pointer rests on the prompt, which holds it open.
    @State private var isPointerResting = false
    /// Whether the pointer has rested on the prompt, after which it closes a
    /// moment after the pointer leaves rather than after its full time.
    @State private var wasRestedOn = false

    var body: some View {
        BrowserCredentialPromptSurface(
            accessibilityLabel: Text(route.title(spaceName: space?.name)),
            accessibilityIdentifier: "crest-password-save",
            width: metrics.savePromptWidth,
            metrics: metrics
        ) {
            BrowserCredentialSavePromptContent(
                candidate: candidate,
                route: route,
                destination: destination,
                space: space,
                namesSystemPasswordsDestination: namesSystemPasswordsDestination,
                metrics: metrics,
                dismiss: port.dismiss,
                neverSave: neverSaveAction,
                perform: perform
            )
        }
        .overlay(alignment: .topLeading) { closeButton }
        .onHover { hovering in
            isPointerResting = hovering
            if hovering { wasRestedOn = true }
        }
        .task(id: candidate.id) {
            await prepare()
        }
        .task(id: countdown) {
            await closeWhenTimeIsUp()
        }
    }

    // MARK: - Closing

    /// What restarts the prompt's countdown: another candidate, the pointer
    /// arriving or leaving, or the prompt starting or stopping asking.
    private struct Countdown: Hashable {
        let candidateID: UUID
        let isPointerResting: Bool
        let closes: Bool
    }

    private var countdown: Countdown {
        Countdown(candidateID: candidate.id, isPointerResting: isPointerResting, closes: model.closesOnItsOwn)
    }

    /// Never for This Website, offered only while the prompt asks.
    private var neverSaveAction: (() -> Void)? {
        guard model.closesOnItsOwn else { return nil }
        return { neverSaveSite() }
    }

    /// The ✕ at the prompt's corner, which puts it away as Not Now does.
    private var closeButton: some View {
        Button(action: port.dismiss) {
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
    /// asking: the Space's time from when it starts asking, and once the
    /// pointer has rested on it, a moment after the pointer leaves. Never
    /// while the pointer rests on it, a save is under way or something failed.
    private func closeWhenTimeIsUp() async {
        guard model.closesOnItsOwn, !isPointerResting else { return }
        let wait: Duration =
            wasRestedOn ? BrowserNotices.graceAfterHover : .seconds(preferences.savePromptSeconds)
        try? await Task.sleep(for: wait)
        guard !Task.isCancelled, model.closesOnItsOwn, !isPointerResting,
            port.presentedCandidateID() == candidate.id
        else { return }
        port.dismiss()
    }

    /// Stops this Space offering to save on the page's site and everything
    /// under it, as a site added in Settings starts, then puts the prompt
    /// away. Saved passwords still fill there.
    private func neverSaveSite() {
        try? browser.neverSaveSite(candidate.topLevelOrigin.host, includesSubdomains: true, in: port.spaceID)
        port.dismiss()
    }

    private var space: BrowserSpaceIdentity? {
        browser.spaceModel(port.spaceID)?.identity
    }

    private var preferences: CredentialPreferences {
        browser.spaceModel(port.spaceID)?.settings.credentialPreferences ?? .seeded
    }

    /// Whether this prompt will go on to offer the password to the system's
    /// Passwords app after Crest has kept it.
    ///
    /// A shell that cannot make the offer never asks the policy: leaving the
    /// closure out of the port is the whole of that shell's answer.
    private var shouldOfferSystemPasswords: Bool {
        port.offerToSystemPasswords != nil && browser.offersSystemPasswordWriteThrough(for: preferences)
    }

    private var route: BrowserCredentialPromptRoute {
        BrowserCredentialPromptRoute(
            phase: model.phase,
            systemPasswordOfferPhase: model.systemPasswordOfferPhase,
            offersSystemPasswords: shouldOfferSystemPasswords
        )
    }

    private var destination: BrowserCredentialPromptDestinationMetadata {
        route.destinationMetadata(
            spaceName: space?.name,
            syncsWithICloud: preferences.syncsCrestPasswordsWithICloud,
            presentation: metrics.destinationPresentation
        )
    }

    /// Whether the destination line already says iCloud in words, which is what
    /// lets it carry the cloud glyph instead of the Space's crest.
    private var namesSystemPasswordsDestination: Bool {
        metrics.destinationPresentation == .combinedStatus
            && preferences.syncsCrestPasswordsWithICloud
    }

    private func perform(_ action: BrowserCredentialPromptPrimaryAction) {
        action.perform(self)
    }

    private func prepare() async {
        await model.prepare(
            candidate: candidate,
            in: port.spaceID,
            browser: browser
        )
        guard !Task.isCancelled,
            port.presentedCandidateID() == candidate.id,
            model.phase == .alreadyStored
        else { return }
        port.dismiss()
    }

    private func offerToSystemPasswords() async {
        guard let offer = port.offerToSystemPasswords else { return }
        await model.offerToSystemPasswords {
            try await offer(
                candidate,
                "\(candidate.username) · \(space?.name ?? "this Space")"
            )
        }
    }
}

// MARK: - Actions - Primary action

extension BrowserCredentialSavePrompt: BrowserCredentialPromptPerformer {
    func save() {
        Task { @MainActor in
            await model.commit(
                candidate: candidate,
                in: port.spaceID,
                browser: browser
            )
            guard port.presentedCandidateID() == candidate.id,
                case .saved = model.phase
            else { return }
            guard shouldOfferSystemPasswords else {
                port.dismiss()
                return
            }
            await offerToSystemPasswords()
            guard model.systemPasswordOfferPhase == .completed else { return }
            port.dismiss()
        }
    }

    func retryPreparation() {
        Task { @MainActor in
            await prepare()
        }
    }

    func retrySystemPasswords() {
        Task { @MainActor in
            await offerToSystemPasswords()
            guard port.presentedCandidateID() == candidate.id,
                model.systemPasswordOfferPhase == .completed
            else { return }
            port.dismiss()
        }
    }
}
