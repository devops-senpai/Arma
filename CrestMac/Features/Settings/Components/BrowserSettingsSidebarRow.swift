import SwiftUI

/// One row of the Settings sidebar: a button that wears the system's
/// selection while its page shows, and Crest's hover surface under the
/// pointer or under a Space dragged onto it.
///
/// The row draws its own selection from `isSelected`, so it looks chosen
/// whether or not the sidebar holds the keyboard, and it is a plain button, so
/// its first click always counts.
struct BrowserSettingsSidebarRow<Label: View, Accessory: View>: View {
    // MARK: - Variables

    @Environment(\.appearsActive) private var appearsActive
    @State private var isHovering = false
    let isSelected: Bool
    var isDropTarget = false
    let action: () -> Void
    /// The row's icon and title, told whether the row wears the emphasized
    /// selection, on which they read in its text colour.
    @ViewBuilder let label: (_ isEmphasized: Bool) -> Label
    /// Controls after the title that keep their own clicks, such as a menu.
    @ViewBuilder let accessory: (_ isEmphasized: Bool) -> Accessory

    /// Whether the row wears the selection of the window in front.
    private var isEmphasized: Bool { isSelected && appearsActive }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                label(isEmphasized)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .padding(.leading, BrowserSettingsSidebarRowMetrics.contentInset)
                    .frame(
                        maxWidth: .infinity, minHeight: BrowserSettingsSidebarRowMetrics.height, alignment: .leading
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            accessory(isEmphasized)
                .padding(.trailing, BrowserSettingsSidebarRowMetrics.contentInset)
        }
        .foregroundStyle(isEmphasized ? BrowserSettingsSidebarRowMetrics.selectedText : Color.primary)
        .background { surface }
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var surface: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: CrestRadius.compact, style: .continuous)
                .fill(
                    appearsActive
                        ? BrowserSettingsSidebarRowMetrics.selection
                        : BrowserSettingsSidebarRowMetrics.inactiveSelection)
        } else {
            Color.clear.crestInteractiveSurface(isSelected: false, isHovering: isHovering || isDropTarget)
        }
    }
}

extension BrowserSettingsSidebarRow where Accessory == EmptyView {
    init(
        isSelected: Bool, isDropTarget: Bool = false, action: @escaping () -> Void,
        @ViewBuilder label: @escaping (_ isEmphasized: Bool) -> Label
    ) {
        self.init(isSelected: isSelected, isDropTarget: isDropTarget, action: action, label: label) { _ in
            EmptyView()
        }
    }
}

enum BrowserSettingsSidebarRowMetrics {
    /// A sidebar row's height, as the system's sidebar lists draw it.
    static let height: CGFloat = 32
    /// How far a row's content sits in from the edge of its highlight.
    static let contentInset: CGFloat = 8
    /// The width a row's icon takes, so titles line up.
    static let iconWidth: CGFloat = 20
    static let iconSpacing: CGFloat = 7
    /// The system's colours for the selected row of a list in the window in
    /// front, its text, and the selected row of a window behind.
    static let selection = Color(nsColor: .selectedContentBackgroundColor)
    static let selectedText = Color(nsColor: .alternateSelectedControlTextColor)
    static let inactiveSelection = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
}
