import SwiftUI

/// A generated password, hidden as dots until revealed, with Reveal, Copy,
/// which puts it on the clipboard for a minute as a saved password is, and
/// Generate, which makes another.
struct BrowserGeneratedPasswordValue: View {
    let password: String
    let regenerate: () -> Void

    @State private var isRevealed = false
    @State private var wasCopied = false

    var body: some View {
        HStack(spacing: CrestSpacing.small) {
            Group {
                if password.isEmpty {
                    Text("No password generated").foregroundStyle(.secondary)
                } else if isRevealed {
                    Text(password).font(.body.monospaced()).textSelection(.enabled)
                } else {
                    Text(String(repeating: "•", count: password.count)).font(.body.monospaced())
                }
            }
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(password.isEmpty ? "No password generated" : "Generated password"))

            if !password.isEmpty {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text(isRevealed ? "Hide Password" : "Show Password"))
                .accessibilityIdentifier("password-generator-reveal")

                Button {
                    wasCopied = BrowserCredentialClipboard.write(.clipboard(password: password))
                } label: {
                    Image(systemName: wasCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text("Copy Password"))
                .accessibilityIdentifier("password-generator-copy")
            }

            Button("Generate", action: regenerate)
                .accessibilityIdentifier("password-generator-generate")
        }
        .onChange(of: password) { wasCopied = false }
    }
}
