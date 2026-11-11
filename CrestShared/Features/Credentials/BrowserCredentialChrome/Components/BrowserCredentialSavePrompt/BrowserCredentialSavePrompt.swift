import SwiftUI

/// The offer to keep the password a form was just submitted with. While it
/// asks, the person can correct the account and password, choose whether the
/// password also fills the site's subdomains, or tell the Space never to save
/// on the site; the prompt stops counting down once they start answering.
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
    /// The candidate as the person corrects it, from the moment the prompt
    /// starts asking.
    @State private var draft: BrowserCredentialSaveCandidate?
    /// Whether the site may reach its subdomains at all.
    @State private var offersSubdomains = false
    /// The categories the Space's saved passwords are filed under.
    @State private var categories: [String] = []
    /// Whether the person has started answering: touched a field or a choice.
    /// From then on the prompt waits for them.
    @State private var isEngaged = false

    /// What a save would keep now.
    private var current: BrowserCredentialSaveCandidate {
        draft ?? candidate
    }

    var body: some View {
        BrowserCredentialPromptSurface(
            accessibilityLabel: Text(route.title(spaceName: space?.name)),
            accessibilityIdentifier: "crest-password-save",
            width: metrics.savePromptWidth,
            metrics: metrics
        ) {
            BrowserCredentialSavePromptContent(
                candidate: current,
                route: route,
                destination: destination,
                space: space,
                namesSystemPasswordsDestination: namesSystemPasswordsDestination,
                metrics: metrics,
                dismiss: port.dismiss,
                neverSave: neverSaveAction,
                fields: fields,
                perform: perform
            )
        }
        .overlay(alignment: .topLeading) { closeButton }
        .onHover { hovering in
            isPointerResting = hovering
        }
        .task(id: candidate.id) {
            begin()
            await prepare(dismissesWhenStored: true)
        }
        .task(id: correction) {
            await replanAfterCorrection()
        }
        .task(id: countdown) {
            await closeWhenTimeIsUp()
        }
    }

    // MARK: - Correcting

    /// What the person may change before saving, which changes what a save
    /// means: a new account, an update, or nothing to do.
    private struct Correction: Hashable {
        let username: String
        let password: String
    }

    private var correction: Correction? {
        guard isEngaged, let draft else { return nil }
        return Correction(username: draft.username, password: draft.password)
    }

    /// The fields, while the prompt asks and nothing is being saved.
    private var fields: BrowserCredentialSaveFields? {
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

    private func draftBinding<Value>(
        _ keyPath: WritableKeyPath<BrowserCredentialSaveCandidate, Value>
    ) -> Binding<Value> {
        Binding(
            get: { current[keyPath: keyPath] },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    /// Starts asking about a new candidate: its subdomains included where the
    /// site allows it, as the person most often wants.
    private func begin() {
        offersSubdomains = browser.allowsSubdomainReach(from: candidate.origin)
        var fresh = candidate
        fresh.includesSubdomains = offersSubdomains
        // A username that is an email address is the account's email too.
        if fresh.username.contains("@") { fresh.email = fresh.username }
        draft = fresh
        Task { @MainActor in
            let saved = (try? await browser.savedCredentialDescriptors(in: port.spaceID)) ?? []
            var names: [String] = []
            for name in saved.compactMap(\.category)
            where !names.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                names.append(name)
            }
            categories = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
        isEngaged = false
    }

    /// Plans the save again once the person stops typing, so the prompt says
    /// whether it saves a new account or updates one already kept.
    private func replanAfterCorrection() async {
        guard correction != nil else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, model.asksForAnswer else { return }
        await prepare(dismissesWhenStored: false)
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
        Countdown(
            candidateID: candidate.id, isPointerResting: isPointerResting, closes: model.closesOnItsOwn && !isEngaged)
    }

    /// Never for This Site, offered only while the prompt asks.
    private var neverSaveAction: (() -> Void)? {
        guard model.asksForAnswer else { return nil }
        return { neverSaveOnSite() }
    }

    /// The ✕ at the prompt's corner, which puts it away as Not Now does.
    private var closeButton: some View {
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
    private func closeWhenTimeIsUp() async {
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
    private func neverSaveOnSite() {
        let host = candidate.topLevelOrigin.host
        do {
            try browser.neverSaveSite(host, includesSubdomains: current.includesSubdomains, in: port.spaceID)
        } catch {
            try? browser.neverSaveSite(host, includesSubdomains: false, in: port.spaceID)
        }
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

    /// Plans the save of what the prompt holds now. A first plan that finds
    /// the password already kept puts the prompt away; a correction that does
    /// says so instead.
    private func prepare(dismissesWhenStored: Bool) async {
        await model.prepare(
            candidate: current,
            in: port.spaceID,
            browser: browser
        )
        guard dismissesWhenStored, !Task.isCancelled,
            port.presentedCandidateID() == candidate.id,
            model.phase == .alreadyStored
        else { return }
        port.dismiss()
    }

    private func offerToSystemPasswords() async {
        guard let offer = port.offerToSystemPasswords else { return }
        await model.offerToSystemPasswords {
            try await offer(
                current,
                "\(current.username) · \(space?.name ?? "this Space")"
            )
        }
    }
}

// MARK: - Actions - Primary action

extension BrowserCredentialSavePrompt: BrowserCredentialPromptPerformer {
    func save() {
        guard !current.username.isEmpty, !current.password.isEmpty,
            current.notes.utf8.count <= credentialNotesByteLimit
        else { return }
        let notes = current.notes
        Task { @MainActor in
            await model.commit(
                candidate: current,
                in: port.spaceID,
                browser: browser
            )
            guard port.presentedCandidateID() == candidate.id,
                case .saved = model.phase
            else { return }
            if !notes.isEmpty, let saved = model.savedDescriptor {
                try? await browser.setCredentialNotes(notes, for: saved)
            }
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
            await prepare(dismissesWhenStored: false)
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
