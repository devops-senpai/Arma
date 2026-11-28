import SwiftUI

/// The split menu's **Arrange** submenu: the ready-made shapes for as many
/// cards as the split holds, each drawn as a small diagram, with the one on
/// show checked. Choosing one keeps the cards in their order and lays them out
/// in its shape.
struct BrowserSplitArrangeMenu: View {
    // MARK: - Static Variables

    private static let leaf = SplitShape.leaf

    /// Every arrangement, for two, three and four cards.
    private static let arrangements: [(title: LocalizedStringResource, shape: SplitShape)] = [
        ("Side by Side", .columns(2)),
        ("Stacked", .along(.vertical, [leaf, leaf])),
        ("Three Across", .columns(3)),
        ("Three Stacked", .along(.vertical, [leaf, leaf, leaf])),
        ("One Left, Two Stacked Right", .along(.horizontal, [leaf, .along(.vertical, [leaf, leaf])])),
        ("Two Stacked Left, One Right", .along(.horizontal, [.along(.vertical, [leaf, leaf]), leaf])),
        ("One Above, Two Below", .along(.vertical, [leaf, .columns(2)])),
        ("Two Above, One Below", .along(.vertical, [.columns(2), leaf])),
        ("Four Across", .columns(4)),
        ("Four Stacked", .along(.vertical, [leaf, leaf, leaf, leaf])),
        ("Grid", .along(.vertical, [.columns(2), .columns(2)])),
        ("One Left, Three Stacked Right", .along(.horizontal, [leaf, .along(.vertical, [leaf, leaf, leaf])])),
        ("Three Stacked Left, One Right", .along(.horizontal, [.along(.vertical, [leaf, leaf, leaf]), leaf])),
        ("One Above, Three Below", .along(.vertical, [leaf, .columns(3)])),
        ("Three Above, One Below", .along(.vertical, [.columns(3), leaf])),
        ("Two Stacked Left, Two Across Right", .along(.horizontal, [.along(.vertical, [leaf, leaf]), leaf, leaf])),
        ("Two Across Left, Two Stacked Right", .along(.horizontal, [leaf, leaf, .along(.vertical, [leaf, leaf])])),
    ]

    // MARK: - Variables

    let configuration: BrowserSidebarSplitGroupRowConfiguration

    /// The shape the split shows: the one it keeps while its leaves count the
    /// members, else its row of columns.
    private var shownShape: SplitShape {
        let count = configuration.members.count
        guard let shape = configuration.choices.shape, shape.leafCount == count else { return .columns(count) }
        return shape
    }

    var body: some View {
        let count = configuration.members.count
        Menu("Arrange", systemImage: "rectangle.split.2x2") {
            ForEach(Self.arrangements.indices.filter { Self.arrangements[$0].shape.leafCount == count }, id: \.self) {
                arrangement($0)
            }
            // A label style set on the menu that opens this one doesn't reach
            // its rows, which macOS then draws as titles alone.
            .crestMenuActionLabelStyle()
        }
        .disabled(!configuration.isAvailableForDisplay || count < 2)
    }

    // MARK: - Actions - Arranging

    private func arrangement(_ index: Int) -> some View {
        let (title, shape) = Self.arrangements[index]
        return Toggle(
            isOn: Binding(
                get: { shownShape == shape },
                set: { chosen in
                    guard chosen, configuration.isCurrentAndUnlocked else { return }
                    configuration.browser.arrangeSplit(
                        configuration.groupID, in: shape, matching: configuration.assignment)
                })
        ) {
            Label {
                Text(title)
            } icon: {
                BrowserSplitArrangementIcon.image(for: shape)
            }
        }
    }
}
