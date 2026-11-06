import SwiftUI
import UniformTypeIdentifiers

/// The Settings pane list: a search field over a column of rows, grouped the
/// way the macOS catalog orders it, with the Spaces between the first group
/// and the rest.
///
/// Every row is a button and the chosen row is drawn from the page Settings
/// shows, so a row answers its first click and shows as chosen whether or not
/// the list holds the keyboard. A Space's row also lifts under a drag, to
/// join another group or to stand elsewhere in the list.
struct BrowserSettingsSidebar: View {
    // MARK: - Types

    private enum Focus: Hashable {
        case search
        case rows
    }

    // MARK: - Variables

    @Environment(\.locale) private var locale
    @State private var pendingDeletion: BrowserSpaceDeletionRequest?
    @State private var pendingGroupChange: BrowserSpaceGroupChange?
    @State private var drag = BrowserSettingsSpaceDrag()
    /// Whether a row's lift gesture is in flight, so one that is cancelled
    /// still lets go of its row.
    @GestureState private var isLifting = false
    @FocusState private var focus: Focus?
    @Bindable var tabState: BrowserSettingsTabState
    let browser: BrowserStore
    let spaceAccess: BrowserSpaceAccessController
    let dataDeleter: any BrowserSpaceDataDeleting
    let openSpace: BrowserSettingsOpenSpaceAction
    let addSpace: () -> Void
    let addSubSpace: (UUID) -> Void

    private var navigation: BrowserSettingsNavigationState { tabState.navigation }
    private var state: CoreState { browser.core.state }
    /// The row that shows as chosen: the shown page's own, or the row it
    /// lives under.
    private var selectedRow: BrowserSettingsSidebarItem { navigation.selection.row }

    var body: some View {
        let groups = visibleGroups
        let spaces = visibleSpaces
        VStack(spacing: 0) {
            BrowserSettingsBuildHeader()
            searchField
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let first = groups.first {
                        destinationRows(first)
                    }
                    if !spaces.isEmpty || navigation.query.isEmpty {
                        spacesHeader
                        spaceRows(spaces)
                    }
                    ForEach(groups.dropFirst(), id: \.self) { group in
                        VStack(alignment: .leading, spacing: 0) { destinationRows(group) }
                            .padding(.top, BrowserSettingsSidebarMetrics.groupSpacing)
                    }
                }
                .padding(.horizontal, BrowserSettingsSidebarMetrics.rowInset)
                .padding(.vertical, BrowserSettingsSidebarMetrics.listPadding)
            }
            .browserNativeScrollState(tabState.sidebarScroll)
            .focusable()
            .focused($focus, equals: .rows)
            .focusEffectDisabled()
            // Choosing another Space shows that Space's own Settings tab, a
            // new sidebar, which takes the keyboard as the one before held it.
            .onAppear { focus = .rows }
            .onMoveCommand { direction in
                moveSelection(direction, through: rows(groups: groups, spaces: spaces))
            }
        }
        .background(BrowserSettingsCanvas.background)
        .browserSpaceDeletionConfirmation(
            $pendingDeletion, browser: browser, spaceAccess: spaceAccess, dataDeleter: dataDeleter
        )
        .browserSpaceGroupChangeConfirmation($pendingGroupChange, browser: browser, spaceAccess: spaceAccess)
        .onChange(of: isLifting) { _, isLifting in
            // A lift that ended, or that the system cancelled, lets go.
            if !isLifting { letGo() }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
            TextField("Search settings", text: $tabState.navigation.searchText)
                .textFieldStyle(.plain).focused($focus, equals: .search)
            if !navigation.searchText.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") { tabState.navigation.searchText = "" }
                    .labelStyle(.iconOnly).buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 7))
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Destinations

    private func destinationRows(_ group: [BrowserSettingsDestination]) -> some View {
        ForEach(group) { destination in
            let item = BrowserSettingsSidebarItem.destination(destination)
            BrowserSettingsSidebarRow(isSelected: selectedRow == item) {
                choose(item)
            } label: { isEmphasized in
                HStack(spacing: BrowserSettingsSidebarRowMetrics.iconSpacing) {
                    Image(systemName: destination.symbol)
                        .imageScale(.large)
                        .foregroundStyle(
                            isEmphasized ? BrowserSettingsSidebarRowMetrics.selectedText : destination.sidebarTint
                        )
                        .frame(width: BrowserSettingsSidebarRowMetrics.iconWidth)
                    Text(destination.navigationTitle).lineLimit(1)
                }
            }
            .accessibilityIdentifier("settings-\(destination.name)")
        }
    }

    /// The catalog's groups, keeping only the destinations the search shows
    /// and the groups it leaves any in.
    private var visibleGroups: [[BrowserSettingsDestination]] {
        let visible = Set(navigation.visibleDestinations(locale: locale, in: state))
        return BrowserPlatformSettingsDestinationCatalog.groups
            .map { group in group.filter(visible.contains) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Spaces

    private var spacesHeader: some View {
        HStack(spacing: BrowserSettingsSidebarMetrics.headerButtonSpacing) {
            Text("Spaces")
            Spacer(minLength: 4)
            if navigation.query.isEmpty {
                Button(action: addSpace) {
                    Image(systemName: "plus").foregroundStyle(.secondary)
                }
                .help("Add Space")
                .accessibilityLabel("Add Space")
                .accessibilityIdentifier("settings-spaces-add")
            }
        }
        .buttonStyle(CrestChromeButtonStyle(controlSize: BrowserSettingsSidebarMetrics.headerButtonSize))
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.leading, BrowserSettingsSidebarMetrics.headerLeadingInset)
        .padding(.trailing, BrowserSettingsSidebarMetrics.headerTrailingInset)
        .frame(height: BrowserSettingsSidebarMetrics.headerHeight)
        .padding(.top, BrowserSettingsSidebarMetrics.headerSpacing)
        .accessibilityElement(children: .contain)
    }

    /// The Spaces' rows, which measure themselves for a drag, show where a
    /// dragged Space would land, and carry the row a drag lifted.
    private func spaceRows(_ spaces: [SpaceModel]) -> some View {
        let placement = placement(among: spaces)
        return VStack(spacing: 0) {
            ForEach(spaces) { space in
                spaceRow(space, joinsGroup: placement?.joinedGroupID == browser.primary(of: space).id)
            }
        }
        .overlay(alignment: .topLeading) { liftedRow }
        .overlay(alignment: .topLeading) {
            if let index = placement?.insertionIndex {
                insertionLine(before: index, among: spaces)
            }
        }
        .coordinateSpace(.named(BrowserSettingsSpaceDrag.coordinateSpace))
    }

    /// A Space's row: its crest and name, a Sub-Space indented under its
    /// primary. Choosing it opens the Space on its Appearance page, as
    /// choosing its crest in the page's crest row does.
    private func spaceRow(_ space: SpaceModel, joinsGroup: Bool) -> some View {
        let item = BrowserSettingsSidebarItem.space(space.id)
        let isSelected = selectedRow == item
        return BrowserSettingsSidebarRow(isSelected: isSelected, isDropTarget: joinsGroup) {
            choose(item)
        } label: { _ in
            spaceLabel(space)
        } accessory: { isEmphasized in
            if isSelected {
                Menu {
                    spaceMenu(space)
                        .crestMenuActionLabelStyle()
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(isEmphasized ? BrowserSettingsSidebarRowMetrics.selectedText : Color.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Space actions")
                .accessibilityLabel("Space actions")
            }
        }
        .opacity(drag.liftedSpaceID == space.id ? BrowserSettingsSidebarMetrics.liftedSourceOpacity : 1)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(BrowserSettingsSpaceDrag.coordinateSpace))
        } action: { frame in
            drag.place(row: space.id, at: frame)
        }
        .onDisappear { drag.place(row: space.id, at: nil) }
        .simultaneousGesture(liftGesture(for: space))
        .onDrop(
            of: [.plainText],
            delegate: BrowserSettingsSpaceRowDrop(
                rowSpaceID: space.id, drag: drag, isHolding: tabState.draggedSpaceID != nil,
                lands: { placement(among: visibleSpaces) != nil }, land: land)
        )
        .contextMenu { spaceMenu(space).crestMenuActionLabelStyle() }
        .accessibilityIdentifier("settings-space-\(space.id)")
    }

    private func spaceLabel(_ space: SpaceModel) -> some View {
        HStack(spacing: BrowserSettingsSidebarRowMetrics.iconSpacing) {
            // A Sub-Space sits under its primary, as a tab sits in a folder.
            if browser.isSubSpace(space) {
                Color.clear.frame(width: BrowserSettingsSidebarMetrics.subSpaceIndent, height: 1)
                    .accessibilityHidden(true)
            }
            BrowserSpaceIdentityIcon(space: space, size: 18)
                .frame(width: BrowserSettingsSidebarRowMetrics.iconWidth)
            Text(space.settings.name.isEmpty ? String(localized: "Untitled Space") : space.settings.name)
                .lineLimit(1)
            if space.settings.requiresAuthentication {
                Spacer(minLength: 4)
                Image(systemName: "lock.fill")
                    .imageScale(.small)
                    .opacity(BrowserSettingsSidebarMetrics.lockOpacity)
                    .padding(.trailing, BrowserSettingsSidebarRowMetrics.contentInset)
                    .accessibilityLabel("Locked")
            }
        }
    }

    private func spaceMenu(_ space: SpaceModel) -> some View {
        BrowserSettingsSpaceMenu(
            browser: browser, space: space, spaceAccess: spaceAccess, openSpace: openSpace, addSubSpace: addSubSpace,
            requestDeletion: { pendingDeletion = $0 }, requestGroupChange: { pendingGroupChange = $0 })
    }

    /// The groups with a Space the search shows, whole: each group's primary
    /// then its Sub-Spaces.
    private var visibleSpaces: [SpaceModel] {
        let tab = navigation.matchingSpaceTab(locale: locale, in: state)
        return browser.spaceGroups
            .filter { group in group.contains { navigation.lists($0, spaceTab: tab) } }
            .flatMap { $0 }
    }

    // MARK: - Dragging Spaces

    /// Lifts a Space's row once the press has travelled, beside the row's
    /// button, which keeps the click.
    private func liftGesture(for space: SpaceModel) -> some Gesture {
        DragGesture(
            minimumDistance: BrowserSettingsSpaceDrag.liftDistance,
            coordinateSpace: .named(BrowserSettingsSpaceDrag.coordinateSpace)
        )
        .updating($isLifting) { _, isLifting, _ in isLifting = true }
        .onChanged { value in
            tabState.draggedSpaceID = space.id
            drag.lift(space.id, from: value.startLocation, to: value.location)
        }
        .onEnded { value in
            tabState.draggedSpaceID = space.id
            drag.lift(space.id, from: value.startLocation, to: value.location)
            // A press that slipped and let go on its own row is still a click.
            let endsOnOwnRow = drag.frame(ofRow: space.id)?.contains(value.location) == true
            if !land(), endsOnOwnRow { open(.space(space.id)) }
        }
    }

    /// Where the dragged Space would land among `spaces`, if anywhere.
    private func placement(among spaces: [SpaceModel]) -> BrowserSettingsSpacePlacement? {
        guard let id = tabState.draggedSpaceID, let space = browser.spaceModel(id),
            let aim = drag.aim(holding: id, among: spaces.map(\.id))
        else { return nil }
        return BrowserSettingsSpacePlacement(of: space, at: aim, among: spaces, in: browser)
    }

    /// Lands the dragged Space where the pointer holds it, asking first when
    /// that changes its group. Answers whether it landed anywhere.
    @discardableResult
    private func land() -> Bool {
        let placement = placement(among: visibleSpaces)
        letGo()
        guard let placement else { return false }
        if let change = placement.land() { pendingGroupChange = change }
        return true
    }

    private func letGo() {
        drag.release()
        tabState.draggedSpaceID = nil
    }

    /// The line a dragged Space would land on, before the row at `index`.
    @ViewBuilder
    private func insertionLine(before index: Int, among spaces: [SpaceModel]) -> some View {
        let next = spaces.indices.contains(index) ? spaces[index] : nil
        let frame = (next ?? spaces.last).flatMap { drag.frame(ofRow: $0.id) }
        if let frame {
            let indent = next.map(browser.isSubSpace) == true ? BrowserSettingsSidebarMetrics.subSpaceLineIndent : 0
            Capsule()
                .fill(.tint)
                .frame(
                    width: max(0, frame.width - indent - 2 * BrowserSettingsSidebarRowMetrics.contentInset),
                    height: BrowserSettingsSidebarMetrics.insertionLineHeight
                )
                .offset(
                    x: frame.minX + indent + BrowserSettingsSidebarRowMetrics.contentInset,
                    y: (next == nil ? frame.maxY : frame.minY) - BrowserSettingsSidebarMetrics.insertionLineHeight / 2
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// The row a drag lifted, following the pointer.
    @ViewBuilder
    private var liftedRow: some View {
        if let id = drag.liftedSpaceID, let space = browser.spaceModel(id), let origin = drag.liftedOrigin,
            let frame = drag.frame(ofRow: id)
        {
            spaceLabel(space)
                .padding(.leading, BrowserSettingsSidebarRowMetrics.contentInset)
                .frame(width: frame.width, height: frame.height, alignment: .leading)
                .crestInteractiveSurface(isSelected: true, isHovering: false)
                .offset(x: origin.x, y: origin.y)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Selection

    /// Chooses row `item` from a click. The click a lift's release reports
    /// is not a choice; the lift decides what its release does.
    private func choose(_ item: BrowserSettingsSidebarItem) {
        guard !drag.suppressesActivation else { return }
        open(item)
    }

    /// Opens what row `item` stands for, and gives the rows the keyboard.
    private func open(_ item: BrowserSettingsSidebarItem) {
        focus = .rows
        item.select(on: tabState) { id in
            // A Space opens on Appearance, unless the search found words on
            // another of its pages.
            openSpace(id, tab: navigation.matchingSpaceTab(locale: locale, in: state) ?? .appearance)
        }
    }

    /// Every row in the order the list shows them.
    private func rows(groups: [[BrowserSettingsDestination]], spaces: [SpaceModel]) -> [BrowserSettingsSidebarItem] {
        (groups.first ?? []).map(BrowserSettingsSidebarItem.destination)
            + spaces.map { .space($0.id) }
            + groups.dropFirst().flatMap { $0 }.map(BrowserSettingsSidebarItem.destination)
    }

    /// Chooses the row above or below the chosen one, as the arrow keys do in
    /// a list.
    private func moveSelection(_ direction: MoveCommandDirection, through rows: [BrowserSettingsSidebarItem]) {
        guard let index = rows.firstIndex(of: selectedRow) else { return }
        let step: Int
        switch direction {
        case .up: step = -1
        case .down: step = 1
        default: return
        }
        guard rows.indices.contains(index + step) else { return }
        open(rows[index + step])
    }
}

private enum BrowserSettingsSidebarMetrics {
    /// How far a row's highlight sits in from each edge of the sidebar.
    static let rowInset: CGFloat = 10
    static let listPadding: CGFloat = 10
    /// The space between two groups of rows.
    static let groupSpacing: CGFloat = 13
    /// The space between a group of rows and the header that follows it.
    static let headerSpacing: CGFloat = 8
    static let headerHeight: CGFloat = 26
    static let headerLeadingInset: CGFloat = 6
    /// Lines the header's button up with the trailing glyphs of the rows.
    static let headerTrailingInset: CGFloat = -3
    static let headerButtonSpacing: CGFloat = 4
    static let headerButtonSize = CGSize(width: 22, height: 22)
    /// How far a Sub-Space's row sits in from its primary's.
    static let subSpaceIndent: CGFloat = 13
    /// How far the landing line sits in among Sub-Spaces.
    static let subSpaceLineIndent: CGFloat = 20
    static let insertionLineHeight: CGFloat = 2
    static let liftedSourceOpacity = 0.35
    static let lockOpacity = 0.6
}

/// Lets a Space's Settings row take a Space dragged in from a group page's
/// crests: the row tells the drag where the pointer holds the Space, and the
/// list lands it as it lands a row of its own.
private struct BrowserSettingsSpaceRowDrop: DropDelegate {
    let rowSpaceID: UUID
    let drag: BrowserSettingsSpaceDrag
    /// Whether a Space of Settings is the thing being dragged.
    let isHolding: Bool
    /// Whether letting go where the pointer is would land the Space.
    let lands: () -> Bool
    let land: () -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        isHolding
    }

    func dropEntered(info: DropInfo) {
        drag.hold(overRow: rowSpaceID, at: info.location)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        drag.hold(overRow: rowSpaceID, at: info.location)
        return DropProposal(operation: lands() ? .move : .forbidden)
    }

    func dropExited(info: DropInfo) {
        drag.leave(row: rowSpaceID)
    }

    func performDrop(info: DropInfo) -> Bool {
        drag.hold(overRow: rowSpaceID, at: info.location)
        return land()
    }
}
