import SwiftUI

/// The generator in a popover: a password made to its options, shown hidden
/// until revealed, which the person can change here for this password, make
/// again, copy or use.
struct BrowserPasswordGeneratorPopover: View {
    let browser: BrowserStore
    let use: (String) -> Void

    @State private var generation: PasswordGeneration = .standard
    @State private var generated = ""

    var body: some View {
        Form {
            Section {
                BrowserGeneratedPasswordValue(password: generated, regenerate: generate)
            }
            Section {
                BrowserPasswordGeneratorOptions(generation: $generation)
            }
            Section {
                Button("Use Password") { use(generated) }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .disabled(generated.isEmpty)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .onAppear(perform: generate)
        .onChange(of: generation) { generate() }
    }

    private func generate() {
        generated =
            (try? BrowserStrongPasswordGenerator.generate(from: browser.strongPasswordRecipe(generation))) ?? ""
    }
}
