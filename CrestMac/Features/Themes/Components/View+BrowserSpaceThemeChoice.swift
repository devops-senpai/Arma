import SwiftUI

extension View {
    /// Offers the themes a Space can wear on its Appearance page: the
    /// Forge draws them as the page's Theme row. Choosing a theme copies its
    /// looks into the Space, as a house or scheme does; No Theme keeps the
    /// look the Space has. Editing the Space's crest here changes no theme.
    func browserSpaceThemeChoice(browser: BrowserStore, space: SpaceModel) -> some View {
        modifier(BrowserSpaceThemeChoiceModifier(browser: browser, space: space))
    }
}

/// The Space's theme choice from the theme library, and the Space's dark
/// look kept to the crest its light look wears.
private struct BrowserSpaceThemeChoiceModifier: ViewModifier {
    // MARK: - Variables

    let browser: BrowserStore
    let space: SpaceModel

    @State private var library = BrowserThemeLibrary.shared
    @State private var problem: String?

    private var themeID: UUID? { library.themeID(of: space.id) }

    private var options: [BrowserSpaceThemeChoice.Option] {
        [BrowserSpaceThemeChoice.Option(id: nil, name: String(localized: "No Theme"), symbol: "circle.slash")]
            + library.entries.map { BrowserSpaceThemeChoice.Option(id: $0.id, name: $0.name, symbol: "paintpalette") }
    }

    /// The crests the worn theme keeps, as this Space would wear them; one
    /// the file misspells is left out.
    private var crests: [BrowserSpaceThemeChoice.Crest] {
        guard let themeID, let kept = library.entry(themeID)?.theme.crests else { return [] }
        let look = space.settings.look
        return kept.compactMap { crest in
            (try? crest.crest(on: look)).map { BrowserSpaceThemeChoice.Crest(name: crest.name, crest: $0) }
        }
    }

    /// The other Spaces wearing this Space's theme, as a sentence lists them.
    private var alsoUsedBy: String? {
        guard let themeID else { return nil }
        let names = library.spaces(wearing: themeID, in: browser).filter { $0.id != space.id }.map(\.settings.name)
        guard !names.isEmpty else { return nil }
        return String(localized: "Also used by \(names.formatted(.list(type: .and)))")
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .environment(
                \.browserSpaceThemeChoice,
                BrowserSpaceThemeChoice(
                    options: options, chosenID: themeID, note: problem ?? alsoUsedBy, choose: choose, crests: crests,
                    keepCrest: { name in
                        themeID.map { library.keepCrest(of: space, named: name, in: $0, browser: browser) }
                    },
                    renameCrest: { name, newName in
                        themeID.map { library.renameCrest(name, to: newName, in: $0, browser: browser) }
                    },
                    removeCrest: { name in themeID.map { library.removeCrest(named: name, from: $0, browser: browser) }
                    })
            )
            .onChange(of: space.settings.look) { _, look in
                library.keepDarkLookIdentity(of: space, as: look, in: browser)
            }
    }

    // MARK: - Mutators

    /// Dresses the Space in theme `id`, or has it wear none for nil, keeping
    /// the look it has.
    private func choose(_ id: UUID?) {
        if let id {
            problem = library.choose(id, for: space.id, in: browser)
        } else {
            library.unlink(space.id)
            problem = nil
        }
    }
}
