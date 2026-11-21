import SwiftUI

extension BrowserCredentialSaveActionRow {
    @ViewBuilder
    var neverSaveAction: some View {
        if let neverSave {
            BrowserCredentialNeverSaveButton(route: route, neverSave: neverSave)
        }
    }
}
