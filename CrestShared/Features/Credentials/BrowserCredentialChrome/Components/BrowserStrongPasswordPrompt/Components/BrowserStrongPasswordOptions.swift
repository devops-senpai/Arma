import SwiftUI

/// The generator's options inside the strong-password prompt, folded away
/// until asked for: how long the password is and which kinds of character it
/// uses. They start from the Space's generator and change this password only.
struct BrowserStrongPasswordOptions: View {
    @Binding var generation: PasswordGeneration

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Options", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: CrestSpacing.small) {
                HStack(spacing: CrestSpacing.small) {
                    Text("Length")
                    Slider(
                        value: Binding(
                            get: { Double(generation.length) },
                            set: { generation.length = Int($0.rounded()) }),
                        in: Double(PasswordGeneration.minimumLength)...Double(PasswordGeneration.maximumLength),
                        step: 1
                    )
                    .accessibilityLabel(Text("Length"))
                    Text("\(generation.length)")
                        .monospacedDigit()
                        .frame(minWidth: 22, alignment: .trailing)
                }
                Grid(
                    alignment: .leading, horizontalSpacing: CrestSpacing.medium,
                    verticalSpacing: CrestSpacing.extraSmall
                ) {
                    GridRow {
                        group("Lowercase", \.lowercase)
                        group("Uppercase", \.uppercase)
                    }
                    GridRow {
                        group("Numbers", \.numbers)
                        group("Symbols", \.symbols)
                    }
                }
            }
            .padding(.top, CrestSpacing.extraSmall)
        }
        .font(.caption)
        .accessibilityIdentifier("crest-strong-password-options")
    }

    /// One kind of character. The last one included stays on, since a
    /// password has to draw from something.
    private func group(_ title: LocalizedStringKey, _ keyPath: WritableKeyPath<PasswordGeneration, Bool>) -> some View {
        Toggle(title, isOn: $generation[dynamicMember: keyPath])
            #if os(macOS)
                .toggleStyle(.checkbox)
            #endif
            .disabled(
                generation[keyPath: keyPath]
                    && [generation.lowercase, generation.uppercase, generation.numbers, generation.symbols].count { $0 }
                        == 1
            )
    }
}
