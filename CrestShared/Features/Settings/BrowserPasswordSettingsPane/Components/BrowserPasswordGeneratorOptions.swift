import SwiftUI

/// How a Space generates passwords: how long they are, set with a slider or
/// typed, and which kinds of character they draw from.
struct BrowserPasswordGeneratorOptions: View {
    // MARK: - Static Variables

    private static let lengthFieldWidth: CGFloat = 44

    // MARK: - Variables

    @Binding var generation: PasswordGeneration

    private var length: Binding<Int> {
        Binding(
            get: { generation.length },
            set: {
                generation.length = min(
                    max($0, PasswordGeneration.minimumLength), PasswordGeneration.maximumLength)
            })
    }

    private var sliderLength: Binding<Double> {
        Binding(get: { Double(generation.length) }, set: { length.wrappedValue = Int($0.rounded()) })
    }

    // MARK: - Actions - Drawing

    var body: some View {
        LabeledContent("Length") {
            HStack(spacing: CrestSpacing.small) {
                Slider(
                    value: sliderLength,
                    in: Double(PasswordGeneration.minimumLength)...Double(PasswordGeneration.maximumLength),
                    step: 1
                )
                .accessibilityLabel(Text("Length"))
                TextField("", value: length, format: .number)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: Self.lengthFieldWidth)
                    .accessibilityLabel(Text("Characters"))
            }
        }
        .accessibilityIdentifier("password-generator-length")

        group("Include lowercase letters", \.lowercase)
        group("Include uppercase letters", \.uppercase)
        group("Include numbers", \.numbers)
        group("Include symbols (%$#@)", \.symbols)
    }

    /// One kind of character. The last one included stays on, since a
    /// password has to draw from something.
    private func group(_ title: LocalizedStringKey, _ keyPath: WritableKeyPath<PasswordGeneration, Bool>) -> some View {
        Toggle(title, isOn: $generation[dynamicMember: keyPath])
            #if os(macOS)
                .toggleStyle(.checkbox)
            #endif
            .disabled(generation[keyPath: keyPath] && includedCount == 1)
    }

    private var includedCount: Int {
        [generation.lowercase, generation.uppercase, generation.numbers, generation.symbols].count { $0 }
    }
}

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
