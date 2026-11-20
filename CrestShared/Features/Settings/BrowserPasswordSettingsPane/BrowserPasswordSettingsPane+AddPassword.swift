import SwiftUI

extension BrowserPasswordSettingsPane {
    func addButton(space: SpaceModel) -> some View {
        Button("Add Password…") {
            passwordEditorRequest = BrowserSavedPasswordEditorRequest(account: nil)
        }
        .disabled(!space.settings.credentialPreferences.isEnabled)
        .accessibilityIdentifier("add-space-password")
    }
}
