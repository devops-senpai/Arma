import SwiftUI

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
