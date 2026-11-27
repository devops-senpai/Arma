import SwiftUI

/// How long a generated password is and which kinds of character it uses.
/// The last kind included stays on, since a password has to draw from
/// something; a site's own rules still bound what is made.
struct BrowserPasswordGenerationControls: View {
    @Binding var generation: PasswordGeneration

    var body: some View {
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
            Grid(alignment: .leading, horizontalSpacing: CrestSpacing.medium, verticalSpacing: CrestSpacing.extraSmall) {
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
        .accessibilityIdentifier("crest-password-generation")
    }

    private func group(_ title: LocalizedStringKey, _ keyPath: WritableKeyPath<PasswordGeneration, Bool>) -> some View {
        Toggle(title, isOn: $generation[dynamicMember: keyPath])
            #if os(macOS)
                .toggleStyle(.checkbox)
            #endif
            .disabled(
                generation[keyPath: keyPath]
                    && [generation.lowercase, generation.uppercase, generation.numbers, generation.symbols].count { $0 }
                        == 1)
    }
}
