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

    @State var model = BrowserCredentialSavePromptModel()
    /// Whether the pointer rests on the prompt, which holds it open.
    @State var isPointerResting = false
    /// The candidate as the person corrects it, from the moment the prompt
    /// starts asking.
    @State var draft: BrowserCredentialSaveCandidate?
    /// Whether the site may reach its subdomains at all.
    @State var offersSubdomains = false
    /// The categories the Space's saved passwords are filed under.
    @State var categories: [String] = []
    /// Whether the person has started answering: touched a field or a choice.
    /// From then on the prompt waits for them.
    @State var isEngaged = false

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
            categories = BrowserStore.credentialCategories(
                in: (try? await browser.savedCredentialDescriptors(in: port.spaceID)) ?? [])
            await prepare(dismissesWhenStored: true)
        }
        .task(id: correction) {
            await replanAfterCorrection()
        }
        .task(id: countdown) {
            await closeWhenTimeIsUp()
        }
    }

    private var space: BrowserSpaceIdentity? {
        browser.spaceModel(port.spaceID)?.identity
    }

    var preferences: CredentialPreferences {
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
    func prepare(dismissesWhenStored: Bool) async {
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
