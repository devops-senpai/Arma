import SwiftUI

/// What the save prompt is about to keep, which the person can complete or
/// correct first: the account's email, username and password, its category,
/// notes, and whether the password should also fill the hosts under the site.
/// Touching a field tells the prompt the person is answering it, so it stops
/// counting down.
struct BrowserCredentialSaveFields: View {
    @Binding var email: String
    @Binding var username: String
    @Binding var password: String
    @Binding var category: String?
    @Binding var notes: String
    @Binding var includesSubdomains: Bool
    /// The categories the Space's saved passwords are filed under.
    let categories: [String]
    /// Whether the site may reach its subdomains at all; a public suffix such
    /// as `github.io` may not, so the choice is not offered there.
    let offersSubdomains: Bool
    let isEditable: Bool
    let engage: () -> Void

    @State private var revealsPassword = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case username
        case password
        case notes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CrestSpacing.small) {
            TextField("Email", text: $email)
                .crestTextField()
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .accessibilityIdentifier("crest-password-save-email")

            TextField("Username", text: $username)
                .crestTextField()
                .focused($focusedField, equals: .username)
                .textContentType(.username)
                .autocorrectionDisabled()
                .accessibilityIdentifier("crest-password-save-username")

            HStack(spacing: CrestSpacing.extraSmall) {
                Group {
                    if revealsPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .password)
                .autocorrectionDisabled()
                .accessibilityIdentifier("crest-password-save-password")

                Button {
                    revealsPassword.toggle()
                    engage()
                } label: {
                    Image(systemName: revealsPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text(revealsPassword ? "Hide Password" : "Show Password"))
                .accessibilityIdentifier("crest-password-save-reveal")
            }
            .crestFieldSurface(isFocused: focusedField == .password)

            BrowserPasswordCategoryPicker(category: $category, categories: categories)
                .font(.callout)

            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(1...3)
                .crestTextField()
                .focused($focusedField, equals: .notes)
                .foregroundStyle(notes.utf8.count > credentialNotesByteLimit ? CrestColor.danger : .primary)
                .accessibilityIdentifier("crest-password-save-notes")

            // A public suffix such as github.io can't include its subdomains.
            Toggle("Include subdomains", isOn: $includesSubdomains)
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                .font(.callout)
                .disabled(!offersSubdomains)
                .accessibilityIdentifier("crest-password-save-subdomains")
        }
        .disabled(!isEditable)
        .onChange(of: focusedField) { _, field in
            if field != nil { engage() }
        }
        .onChange(of: includesSubdomains) { engage() }
        .onChange(of: category) { engage() }
    }
}
