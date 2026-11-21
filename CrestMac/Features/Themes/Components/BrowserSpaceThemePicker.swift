import SwiftUI

/// The theme a Space wears, heading its Appearance page above the editor, and
/// the other Spaces wearing the same theme. Choosing a theme copies its looks
/// into the Space, as a house or scheme does; while the Space keeps wearing
/// it, editing the Space's look here saves over the theme, and editing the
/// theme under Settings › Themes dresses the Space again.
struct BrowserSpaceThemePicker: View {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    @State private var library = BrowserThemeLibrary.shared
    @State private var problem: String?

    private var themeID: UUID? { library.themeID(of: space.id) }

    private var currentName: String {
        themeID.flatMap(library.entry)?.name ?? String(localized: "No Theme")
    }

    /// The other Spaces wearing this Space's theme, as a sentence lists them.
    private var alsoUsedBy: String? {
        guard let themeID else { return nil }
        let names = library.spaces(wearing: themeID, in: browser).filter { $0.id != space.id }.map(\.settings.name)
        guard !names.isEmpty else { return nil }
        return String(localized: "Also used by \(names.formatted(.list(type: .and)))")
    }

    // MARK: - Actions - Presentation

    var body: some View {
        HStack(spacing: CrestSpacing.medium) {
            Text("Theme")
            Menu {
                Group {
                    Toggle(isOn: chosen(nil)) {
                        Label("No Theme", systemImage: "circle.slash")
                    }
                    Divider()
                    ForEach(library.entries) { entry in
                        Toggle(isOn: chosen(entry.id)) {
                            Label(entry.name, systemImage: "paintpalette")
                        }
                    }
                }
                .crestMenuActionLabelStyle()
            } label: {
                Text(currentName)
            }
            .fixedSize()
            .help("The theme this Space wears; edit themes in Settings › Themes")
            .accessibilityIdentifier("space-theme-picker")
            if let alsoUsedBy {
                Text(alsoUsedBy)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let problem {
                Text(problem).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, CrestSpacing.large)
        .padding(.vertical, CrestSpacing.small)
        .onChange(of: space.settings.look) { _, look in
            library.keepDarkLookIdentity(of: space, as: look, in: browser)
            library.spaceEdited(space.id, in: browser)
        }
    }

    /// Whether the Space wears theme `id`, or none for nil; choosing a theme
    /// dresses the Space in it, and choosing none keeps the look it has.
    private func chosen(_ id: UUID?) -> Binding<Bool> {
        Binding(
            get: { themeID == id },
            set: { isOn in
                guard isOn else { return }
                if let id {
                    problem = library.choose(id, for: space.id, in: browser)
                } else {
                    library.unlink(space.id)
                    problem = nil
                }
            })
    }
}
