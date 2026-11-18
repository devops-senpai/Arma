import SwiftUI

/// How a generated password is made: how long it is, set with a slider or
/// typed, and which kinds of character it draws from.
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
