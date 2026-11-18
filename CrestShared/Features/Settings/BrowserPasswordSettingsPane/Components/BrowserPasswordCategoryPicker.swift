import SwiftUI

/// The category a saved password is filed under: none, one the Space already
/// uses, or a new one the person names.
struct BrowserPasswordCategoryPicker: View {
    @Binding var category: String?
    let categories: [String]

    @State private var isNaming = false
    @State private var newName = ""
    @FocusState private var isTyping: Bool

    private enum Choice: Hashable {
        case none
        case named(String)
        case new
    }

    /// The menu's choices, the current one among them even when no other
    /// password uses it yet.
    private var choices: [String] {
        guard let category, !categories.contains(category) else { return categories }
        return (categories + [category]).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        if isNaming {
            LabeledContent("Category") {
                HStack(spacing: CrestSpacing.small) {
                    TextField("", text: $newName, prompt: Text("New Category"))
                        .labelsHidden()
                        .focused($isTyping)
                        .onSubmit(name)
                        .accessibilityIdentifier("saved-password-new-category")
                    Button(action: name) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(CrestChromeButtonStyle())
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel(Text("Add Category"))
                    Button {
                        isNaming = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(CrestChromeButtonStyle())
                    .accessibilityLabel(Text("Cancel"))
                }
            }
        } else {
            Picker("Category", selection: selection) {
                Text("None").tag(Choice.none)
                ForEach(choices, id: \.self) { name in
                    Text(name).tag(Choice.named(name))
                }
                Divider()
                Text("New Category…").tag(Choice.new)
            }
            .accessibilityIdentifier("saved-password-category")
        }
    }

    private var selection: Binding<Choice> {
        Binding(
            get: { category.map(Choice.named) ?? .none },
            set: { choice in
                switch choice {
                case .none: category = nil
                case .named(let name): category = name
                case .new:
                    newName = ""
                    isNaming = true
                    isTyping = true
                }
            })
    }

    private func name() {
        guard let named = BrowserStore.credentialCategory(newName) else { return }
        category = named
        isNaming = false
    }
}
