import SwiftUI

// MARK: - Types

/// What the saved-password editor opens on: a saved password, or a new one.
struct BrowserSavedPasswordEditorRequest: Identifiable {
    let id = UUID()
    let account: CredentialDescriptor?
    /// The website a new password starts with.
    var website: String?
}

/// One saved password, to add or change: the website, the category it is
/// filed under, its email, username and password, which the Space's generator
/// can make, and notes such as recovery codes, kept as secret as the password.
/// Changing a saved password authenticates first, as viewing it does.
struct BrowserSavedPasswordEditor: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel
    /// The saved password being changed, or nil for a new one.
    let account: CredentialDescriptor?
    /// The website a new password starts with.
    var website: String? = nil
    /// The categories the Space's saved passwords are filed under.
    let categories: [String]
    let saved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var typedWebsite = ""
    @State private var category: String?
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var notes = ""
    @State private var revealsPassword = false
    @State private var isUnlocked = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var notesBytes: Int { notes.utf8.count }

    /// Where the password signs in: the saved one's own origin, or the
    /// website typed for a new one, read as `https` unless it names a scheme.
    private var address: URL? {
        if let account { return URL(string: account.origin.description) }
        let typed = typedWebsite.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return nil }
        let url = URL(string: typed.contains("://") ? typed : "https://\(typed)")
        return url?.host() == nil ? nil : url
    }

    private var canSave: Bool {
        isUnlocked && !isSaving && address != nil && !username.isEmpty && !password.isEmpty
            && notesBytes <= credentialNotesByteLimit
    }

    // MARK: - Actions - Drawing

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let account {
                        LabeledContent("Website", value: account.origin.host)
                    } else {
                        TextField("Website", text: $typedWebsite, prompt: Text(verbatim: "example.com"))
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("saved-password-website")
                    }
                    BrowserPasswordCategoryPicker(category: $category, categories: categories)
                }

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("saved-password-email")
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("saved-password-username")
                    passwordRow
                }

                Section {
                    TextEditor(text: $notes)
                        .font(.body)
                        .frame(minHeight: 96)
                        .accessibilityIdentifier("saved-password-notes")
                } header: {
                    Text("Notes")
                } footer: {
                    Text("\(notesBytes) of \(credentialNotesByteLimit) bytes")
                        .crestFormFootnote()
                        .foregroundStyle(
                            notesBytes > credentialNotesByteLimit ? CrestColor.danger : CrestColor.textSecondary)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(CrestColor.danger)
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(!isUnlocked)
            .navigationTitle(account == nil ? "New Password" : "Edit Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
        .crestSheetSize(minWidth: 420, idealWidth: 480, minHeight: 520, idealHeight: 600)
        .task { await unlock() }
        .onDisappear(perform: forget)
    }

    private var passwordRow: some View {
        LabeledContent("Password") {
            HStack(spacing: CrestSpacing.extraSmall) {
                Group {
                    if revealsPassword {
                        TextField("", text: $password)
                    } else {
                        SecureField("", text: $password)
                    }
                }
                .labelsHidden()
                .autocorrectionDisabled()
                .accessibilityIdentifier("saved-password-password")

                Button {
                    revealsPassword.toggle()
                } label: {
                    Image(systemName: revealsPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text(revealsPassword ? "Hide Password" : "Show Password"))

                Button("Generate") {
                    if let generated = try? BrowserStrongPasswordGenerator.generate(from: browser.strongPasswordRecipe()) {
                        password = generated
                    }
                }
                .accessibilityIdentifier("saved-password-generate")
            }
        }
    }

    // MARK: - Actions - Editing

    /// Reads the saved password and its notes once the person authenticates;
    /// a new one has nothing to read.
    private func unlock() async {
        guard let account else {
            typedWebsite = website ?? ""
            isUnlocked = true
            return
        }
        category = account.category
        do {
            let credential = try await BrowserCredentialSensitiveAccess(browser: browser).revealCredential(
                id: account.id, in: account.spaceID,
                reason: String(localized: "Authenticate to edit this Arma password."))
            email = credential.descriptor.email ?? ""
            username = credential.descriptor.username
            password = credential.password
            notes = try await browser.credentialNotes(for: account) ?? ""
            isUnlocked = true
        } catch {
            errorMessage = String(localized: "Arma couldn’t open this password.")
        }
    }

    private func save() {
        guard canSave, let address else { return }
        isSaving = true
        errorMessage = nil
        Task { @MainActor in
            defer { isSaving = false }
            do {
                let descriptor = try await browser.saveCredential(
                    username: username, password: password, for: address, in: account?.spaceID ?? space.id,
                    replacing: account, email: email, category: category ?? "")
                try await browser.setCredentialNotes(notes, for: descriptor)
                forget()
                saved()
                dismiss()
            } catch let rejection as Rejection {
                errorMessage = rejection.explanation
            } catch CredentialVaultError.insecureOrigin {
                errorMessage = String(localized: "Arma saves passwords only for secure (https) websites.")
            } catch {
                errorMessage = String(localized: "Arma couldn’t save this password.")
            }
        }
    }

    /// Drops the password and notes from memory.
    private func forget() {
        password = ""
        notes = ""
    }
}
