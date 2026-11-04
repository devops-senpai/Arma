import SwiftUI

#if os(macOS)
    import AppKit
#endif

/// The websites a Space never offers to save passwords on, one row each with
/// whether it covers its subdomains, which a person adds, edits and removes.
/// Saved passwords still fill on those websites.
struct BrowserNeverSavedSitesSection: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    /// The site being added, while a person types one in.
    @State private var newSite: String?
    @State private var newIncludesSubdomains = true
    /// Why the core refused the site a person tried to add, if it did.
    @State private var refusal: String?
    @FocusState private var isTypingNewSite: Bool
    /// Each new row is a new view, so it never shows the text or choice of
    /// the row before it, which a text field still editing would keep.
    @State private var newSiteRowID = UUID()

    private var sites: [NeverSavedSite] { space.settings.credentialPreferences.neverSavedSites }

    // MARK: - Actions - Drawing

    var body: some View {
        Section {
            ForEach(sites, id: \.host) { site in
                BrowserNeverSavedSiteRow(
                    site: site,
                    save: { text, includesSubdomains throws(Rejection) in
                        try browser.neverSaveSite(
                            text, includesSubdomains: includesSubdomains, replacing: site, in: space.id)
                    },
                    forget: { browser.forgetNeverSavedSite(site, in: space.id) }
                )
            }
            if sites.isEmpty, newSite == nil {
                Text("No sites").foregroundStyle(.secondary)
            }
            if let newSite {
                newSiteRow(newSite).id(newSiteRowID)
            }
            Button {
                beginAdding()
            } label: {
                Label("Add Site", systemImage: "plus")
            }
            .disabled(newSite != nil)
            .accessibilityIdentifier("never-saved-site-add")
        } header: {
            Text("Never Save Passwords On")
        } footer: {
            if let refusal {
                Text(refusal).crestFormFootnote().foregroundStyle(CrestColor.danger)
            } else {
                CrestFormFootnote(
                    "Passwords are never offered to save on these sites; saved passwords still fill there. Include subdomains to cover every address under a site as well, such as mail.example.com."
                )
            }
        }
    }

    /// The row a new site is typed into: its name, whether it covers its
    /// subdomains, and saving or cancelling it.
    private func newSiteRow(_ text: String) -> some View {
        HStack(spacing: CrestSpacing.small) {
            TextField("", text: Binding(get: { text }, set: { newSite = $0 }), prompt: Text(verbatim: "example.com"))
                .labelsHidden()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focused($isTypingNewSite)
                .onSubmit(add)
                #if os(macOS)
                    .onExitCommand(perform: cancelAdding)
                #endif
                .accessibilityIdentifier("never-saved-site-new")
            Toggle("Include subdomains", isOn: $newIncludesSubdomains)
                .accessibilityLabel(Text("Never save on its subdomains too"))
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
            Button(action: add) {
                Image(systemName: "checkmark")
            }
            .buttonStyle(CrestChromeButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel(Text("Save Site"))
            Button(action: cancelAdding) {
                Image(systemName: "xmark")
            }
            .buttonStyle(CrestChromeButtonStyle())
            .accessibilityLabel(Text("Cancel"))
        }
    }

    // MARK: - Actions - Editing

    private func beginAdding() {
        freshRow()
        refusal = nil
    }

    private func cancelAdding() {
        isTypingNewSite = false
        newSite = nil
        refusal = nil
    }

    /// An empty row with Include subdomains on, ready for the next site.
    /// The window's field editor keeps the text of the field it last edited
    /// until editing ends, and a new field it takes over would show that
    /// text, so editing ends and the old row goes before the new one comes.
    private func freshRow() {
        isTypingNewSite = false
        #if os(macOS)
            NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
        newSite = nil
        Task { @MainActor in
            newSite = ""
            newIncludesSubdomains = true
            newSiteRowID = UUID()
            isTypingNewSite = true
        }
    }

    private func add() {
        guard let text = newSite?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        do throws(Rejection) {
            try browser.neverSaveSite(text, includesSubdomains: newIncludesSubdomains, in: space.id)
            refusal = nil
            freshRow()
        } catch {
            refusal = error.explanation
        }
    }
}

/// How often a Space asks the person to authenticate before it shows or
/// copies a saved password. A choice that lowers how well the passwords are
/// kept, such as Don't Ask, takes effect only once the person confirms it.
struct BrowserCredentialAuthenticationRow: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    /// The choice waiting for the person to confirm it.
    @State private var pending: CredentialAuthentication?

    private var choice: Binding<CredentialAuthentication> {
        let stored = browser.credentialPreferenceBinding(\.authentication, in: space)
        return Binding(
            get: { stored.wrappedValue },
            set: { chosen in
                if chosen.confirmsChoosing { pending = chosen } else { stored.wrappedValue = chosen }
            })
    }

    // MARK: - Actions - Drawing

    var body: some View {
        Picker("Ask to authenticate", selection: choice) {
            ForEach(CredentialAuthentication.all, id: \.self) { option in
                Text(option.title).tag(option)
            }
        }
        .accessibilityIdentifier("space-credential-authentication")
        .alert(
            "Stop Asking to Authenticate?",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            presenting: pending
        ) { chosen in
            Button("Don’t Ask", role: .destructive) {
                browser.credentialPreferenceBinding(\.authentication, in: space).wrappedValue = chosen
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: { _ in
            Text(
                "Anyone using this device while you are signed in could view or copy this Space’s saved passwords without authenticating. Exporting passwords still asks."
            )
        }
    }
}

/// How long a Space's offer to save a password stays up, in seconds.
struct BrowserSavePromptSecondsRow: View {
    // MARK: - Static Variables

    private static let fieldWidth: CGFloat = 44

    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    private var seconds: Binding<Int> {
        browser.credentialPreferenceBinding(\.savePromptSeconds, in: space)
    }

    // MARK: - Actions - Drawing

    var body: some View {
        LabeledContent("Close save prompt after") {
            HStack(spacing: CrestSpacing.small) {
                TextField("", value: seconds, format: .number)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: Self.fieldWidth)
                    .accessibilityLabel(Text("Seconds"))
                Stepper(
                    "",
                    value: seconds,
                    in: CredentialPreferences.minimumSavePromptSeconds...CredentialPreferences.maximumSavePromptSeconds
                )
                .labelsHidden()
                Text("seconds")
            }
        }
        .accessibilityIdentifier("space-save-prompt-seconds")
    }
}

/// One website a Space never offers to save passwords on: its name, with
/// `*.` while it covers its subdomains, whether it does, and what edits and
/// removes it. An edited name is checked by the core like a new one, and its
/// `*.` alone says whether it keeps covering subdomains.
private struct BrowserNeverSavedSiteRow: View {
    // MARK: - Variables

    let site: NeverSavedSite
    let save: (String, Bool) throws(Rejection) -> Void
    let forget: () -> Void

    @State private var draft: String?
    @State private var refusal: String?
    @FocusState private var isEditing: Bool

    private var name: String { site.includesSubdomains ? "*.\(site.host)" : site.host }

    // MARK: - Actions - Drawing

    var body: some View {
        VStack(alignment: .leading, spacing: CrestSpacing.extraSmall) {
            HStack(spacing: CrestSpacing.small) {
                nameField
                Toggle("Include subdomains", isOn: includesSubdomains)
                    .accessibilityLabel(Text("Never save on subdomains of \(site.host) too"))
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #endif
                editButton
                Button(action: forget) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text("Remove \(name)"))
            }
            if let refusal {
                Text(refusal).font(.caption).foregroundStyle(CrestColor.danger)
            }
        }
    }

    /// Edits the name, or saves the edit while one is under way.
    @ViewBuilder
    private var editButton: some View {
        if draft == nil {
            Button(action: beginEditing) {
                Image(systemName: "pencil")
            }
            .buttonStyle(CrestChromeButtonStyle())
            .accessibilityLabel(Text("Edit \(name)"))
        } else {
            Button(action: commit) {
                Image(systemName: "checkmark")
            }
            .buttonStyle(CrestChromeButtonStyle())
            .accessibilityLabel(Text("Save \(name)"))
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if let draft {
            TextField(
                "", text: Binding(get: { draft }, set: { self.draft = $0 }), prompt: Text(verbatim: "example.com")
            )
            .labelsHidden()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($isEditing)
            .onSubmit(commit)
            #if os(macOS)
                .onExitCommand { self.draft = nil }
            #endif
        } else {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
                .onTapGesture(count: 2, perform: beginEditing)
        }
    }

    private var includesSubdomains: Binding<Bool> {
        Binding(
            get: { site.includesSubdomains },
            set: { includes in
                refusal = nil
                try? save(site.host, includes)
            })
    }

    // MARK: - Actions - Editing

    private func beginEditing() {
        draft = name
        refusal = nil
        isEditing = true
    }

    private func commit() {
        guard let draft else { return }
        do throws(Rejection) {
            try save(draft, false)
            self.draft = nil
            refusal = nil
        } catch {
            refusal = error.explanation
        }
    }
}
