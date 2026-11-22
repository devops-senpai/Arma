import SwiftUI

extension TextField where Label == Text {
    /// SwiftUI's initializer that titles a field with a
    /// `LocalizedStringResource` needs macOS 26. This one stands in for it on
    /// every macOS, through the label initializer macOS 15 has. It is
    /// disfavored, as SwiftUI's is, so a string literal stays a
    /// `LocalizedStringKey`.
    @_disfavoredOverload
    init(_ titleResource: LocalizedStringResource, text: Binding<String>) {
        self.init(text: text) { Text(titleResource) }
    }
}
