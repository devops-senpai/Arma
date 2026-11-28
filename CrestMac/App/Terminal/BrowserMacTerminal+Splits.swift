import AppKit

/// `arma split`, run in the app through the same core intents the sidebar's
/// Split View menus and drags send, from the front window that shows the
/// split's Space.
extension TerminalSplitCommand {
    // MARK: - Types

    private struct SplitRow: Encodable {
        let id: UUID
        let space: String
        let title: String
        let layout: String
        let tabs: [SplitMember]
    }

    private struct SplitMember: Encodable {
        let id: UUID
        let title: String
    }

    /// A layout `arrange` takes by name: the shapes the split menu's
    /// Arrange submenu offers, in the same order.
    private struct Layout {
        let name: String
        let title: String
        let shape: SplitShape
    }

    private typealias Refusal = BrowserMacTerminal.Refusal
    private typealias FoundTab = BrowserMacTerminal.FoundTab

    // MARK: - Static Variables

    private static let layouts: [Layout] = {
        let leaf = SplitShape.leaf
        func stacked(_ count: Int) -> SplitShape { .along(.vertical, Array(repeating: leaf, count: count)) }
        return [
            Layout(name: "two-across", title: "Side by Side", shape: .columns(2)),
            Layout(name: "two-stacked", title: "Stacked", shape: stacked(2)),
            Layout(name: "three-across", title: "Three Across", shape: .columns(3)),
            Layout(name: "three-stacked", title: "Three Stacked", shape: stacked(3)),
            Layout(
                name: "one-then-two-stacked", title: "One Left, Two Stacked Right",
                shape: .along(.horizontal, [leaf, stacked(2)])),
            Layout(
                name: "two-stacked-then-one", title: "Two Stacked Left, One Right",
                shape: .along(.horizontal, [stacked(2), leaf])),
            Layout(
                name: "one-then-two-across", title: "One Above, Two Below",
                shape: .along(.vertical, [leaf, .columns(2)])),
            Layout(
                name: "two-across-then-one", title: "Two Above, One Below",
                shape: .along(.vertical, [.columns(2), leaf])),
            Layout(name: "four-across", title: "Four Across", shape: .columns(4)),
            Layout(name: "four-stacked", title: "Four Stacked", shape: stacked(4)),
            Layout(name: "grid", title: "Grid", shape: .along(.vertical, [.columns(2), .columns(2)])),
            Layout(
                name: "one-then-three-stacked", title: "One Left, Three Stacked Right",
                shape: .along(.horizontal, [leaf, stacked(3)])),
            Layout(
                name: "three-stacked-then-one", title: "Three Stacked Left, One Right",
                shape: .along(.horizontal, [stacked(3), leaf])),
            Layout(
                name: "one-then-three-across", title: "One Above, Three Below",
                shape: .along(.vertical, [leaf, .columns(3)])),
            Layout(
                name: "three-across-then-one", title: "Three Above, One Below",
                shape: .along(.vertical, [.columns(3), leaf])),
            Layout(
                name: "two-stacked-then-two", title: "Two Stacked Left, Two Across Right",
                shape: .along(.horizontal, [stacked(2), leaf, leaf])),
            Layout(
                name: "two-then-two-stacked", title: "Two Across Left, Two Stacked Right",
                shape: .along(.horizontal, [leaf, leaf, stacked(2)])),
        ]
    }()

    // MARK: - Actions - Running

    @MainActor
    func run(in terminal: BrowserMacTerminal) throws(BrowserMacTerminal.Refusal) -> TerminalOutput {
        switch self {
        case .list(let name):
            return try list(space: name, in: terminal)
        case .create(let references, let rows):
            return try create(references, rows: rows, in: terminal)
        case .add(let reference, let targetReference):
            let found = try terminal.tab(reference)
            let target = try terminal.tab(targetReference)
            guard found.space.id == target.space.id else {
                throw Refusal(
                    "A split's tabs share one Space. Move \(found.tab.displayTitle) with arma tab move first.")
            }
            let browser = try Self.browser(showing: found.space, in: terminal)
            let join = JoinSplit(
                workspaceID: browser.family.workspaceID, windowID: browser.windowID, spaceID: found.space.id,
                tabID: found.tab.id, targetTabID: target.tab.id, index: nil, shape: nil)
            if let refusal = browser.family.refusal(of: join, from: browser) {
                throw Refusal(refusal.placementExplanation)
            }
            let item = BrowserTabDragItem(
                tabID: found.tab.id, spaceID: found.space.id, profileID: found.space.profileID)
            guard browser.addTabToSplit(item, joining: target.tab.id, at: nil) else {
                throw Refusal("Arma could not add that tab to the split.")
            }
            return TerminalOutput(text: "Added \(found.tab.displayTitle) to \(target.tab.displayTitle)'s split.")
        case .remove(let reference):
            let found = try Self.member(reference, in: terminal)
            let browser = try Self.browser(showing: found.space, in: terminal)
            guard browser.removeTabFromSplit(found.tab.id, matching: Self.assignment(of: found.space)) else {
                throw Refusal("Arma could not take that tab out of its split.")
            }
            return TerminalOutput(text: "Took \(found.tab.displayTitle) out of its split.")
        case .dissolve(let reference):
            let found = try Self.member(reference, in: terminal)
            let browser = try Self.browser(showing: found.space, in: terminal)
            guard browser.dissolveSplit(containing: found.tab.id, matching: Self.assignment(of: found.space)) else {
                throw Refusal("Arma could not end that split.")
            }
            return TerminalOutput(text: "Ended the split; its tabs stay, each on its own.")
        case .arrange(let reference, let name):
            let found = try Self.member(reference, in: terminal)
            guard let layout = Self.layouts.first(where: { $0.name == name.lowercased() }) else {
                let names = Self.layouts.map(\.name).joined(separator: ", ")
                throw Refusal("There is no layout '\(name)'. The layouts are \(names).")
            }
            return try arrange(found, as: layout, in: terminal)
        }
    }

    // MARK: - Actions - Listing

    @MainActor
    private func list(space name: String?, in terminal: BrowserMacTerminal) throws(Refusal) -> TerminalOutput {
        var spaces = terminal.spaces.filter { !terminal.application.spaceAccess.isLocked($0) }
        if let name { spaces = [try terminal.unlocked(try terminal.space(name))] }
        var rows: [SplitRow] = []
        for space in spaces {
            // A split keeps a record only once it is named, tinted or tiled;
            // its tabs always name it.
            var groupIDs: [UUID] = []
            for tab in space.tabs.models {
                if let id = tab.splitGroupID, !groupIDs.contains(id) { groupIDs.append(id) }
            }
            for groupID in groupIDs {
                let group = space.splitGroups.first { $0.id == groupID }
                var members = space.splitMembers(of: groupID)
                if members.isEmpty { members = space.tabs.models.filter { $0.splitGroupID == groupID } }
                rows.append(
                    SplitRow(
                        id: groupID, space: space.settings.name,
                        title: group?.displayTitle ?? String(localized: "Split View"),
                        layout: Self.layoutName(of: group?.shape, members: members.count),
                        tabs: members.map { SplitMember(id: $0.id, title: $0.displayTitle) }))
            }
        }
        guard !rows.isEmpty else { return TerminalOutput(text: "No splits.", value: ["splits": rows]) }
        var lines: [String] = []
        for row in rows {
            lines.append("\(row.space): \(row.title) (\(row.layout))")
            for member in row.tabs {
                lines.append("  " + BrowserMacTerminal.short(member.id) + "  " + String(member.title.prefix(60)))
            }
        }
        return TerminalOutput(text: lines.joined(separator: "\n"), value: ["splits": rows])
    }

    /// How a split lays its tabs out, in the words `arrange` takes where one
    /// fits.
    private static func layoutName(of shape: SplitShape?, members: Int) -> String {
        // A shape whose leaves don't count the members is not on show; the
        // split shows its row of columns, as the split view does.
        guard let shape, shape.leafCount == members, let axis = shape.axis else { return "columns" }
        if let layout = layouts.first(where: { $0.shape == shape }) { return layout.name }
        guard shape.children.allSatisfy({ $0.children.isEmpty }) else { return "tiled" }
        return axis.isHorizontal ? "columns" : "rows"
    }

    // MARK: - Actions - Creating

    @MainActor
    private func create(_ references: [String], rows: Bool, in terminal: BrowserMacTerminal) throws(Refusal)
        -> TerminalOutput
    {
        var found: [FoundTab] = []
        for reference in references {
            let tab = try terminal.tab(reference)
            guard !found.contains(where: { $0.tab.id == tab.tab.id }) else { throw Refusal("Name each tab once.") }
            found.append(tab)
        }
        let space = found[0].space
        if let other = found.first(where: { $0.space.id != space.id }) {
            throw Refusal(
                "A split's tabs share one Space, and \(other.tab.displayTitle) is in \(other.space.settings.name).")
        }
        let browser = try Self.browser(showing: space, in: terminal)
        let ids = found.map(\.tab.id)
        // Rows are the stacked layout for as many tabs, which the split
        // menu offers for up to four.
        let stacked = Self.layouts.first { layout in
            rows && layout.shape.leafCount == ids.count && layout.shape.axis?.isHorizontal == false
                && layout.shape.children.allSatisfy { $0.children.isEmpty }
        }
        let split = SplitTabs(
            workspaceID: browser.family.workspaceID, windowID: browser.windowID, spaceID: space.id,
            selection: TabSelection(tabIDs: ids, folderIDs: [], memberTabIDs: ids), targetTabID: nil, index: nil,
            shape: stacked?.shape)
        if let refusal = browser.family.refusal(of: split, from: browser) {
            throw Refusal(refusal.placementExplanation)
        }
        guard browser.sendCopying(split, in: space.id) != nil else {
            throw Refusal("Arma could not make that split.")
        }
        let made = "Showing \(found.count) tabs in Split View."
        guard rows else { return TerminalOutput(text: made) }
        guard stacked != nil else {
            return TerminalOutput(text: made + " Rows hold up to 4 tabs, so they stay in columns.")
        }
        return TerminalOutput(text: "Showing \(found.count) tabs in Split View, in stacked rows.")
    }

    @MainActor
    private func arrange(_ found: FoundTab, as layout: Layout, in terminal: BrowserMacTerminal) throws(Refusal)
        -> TerminalOutput
    {
        guard let groupID = found.tab.splitGroupID else { throw Refusal("\(found.tab.displayTitle) is in no split.") }
        let members = found.space.tabs.models.filter { $0.splitGroupID == groupID }.count
        guard layout.shape.leafCount == members else {
            let fits = Self.layouts.filter { $0.shape.leafCount == members }.map(\.name)
            throw Refusal(
                "\(layout.name) lays out \(layout.shape.leafCount) tabs and this split has \(members). "
                    + "Its layouts are \(fits.joined(separator: ", ")).")
        }
        let browser = try Self.browser(showing: found.space, in: terminal)
        guard browser.arrangeSplit(groupID, in: layout.shape, matching: Self.assignment(of: found.space)) else {
            throw Refusal("Arma could not lay out that split as \(layout.name).")
        }
        return TerminalOutput(text: "Laid out the split as \(layout.title).")
    }

    // MARK: - Actions - Values

    /// The tab `reference` names, when it is in a split.
    @MainActor
    private static func member(_ reference: String, in terminal: BrowserMacTerminal) throws(Refusal) -> FoundTab {
        let found = try terminal.tab(reference)
        guard found.tab.splitGroupID != nil else { throw Refusal("\(found.tab.displayTitle) is in no split.") }
        return found
    }

    /// The store of the front window over `space`, showing it: the split
    /// intents act in the Space a window shows, as they do from its sidebar.
    @MainActor
    private static func browser(showing space: SpaceModel, in terminal: BrowserMacTerminal) throws(Refusal)
        -> BrowserStore
    {
        let space = try terminal.unlocked(space)
        guard let window = terminal.frontWindow(over: space) else {
            throw Refusal("No Arma window is open. Run arma window open.")
        }
        window.browser.selectSpace(space.id)
        return window.browser
    }

    @MainActor
    private static func assignment(of space: SpaceModel) -> BrowserSpaceRuntimeAssignment {
        BrowserSpaceRuntimeAssignment(spaceID: space.id, profileID: space.profileID)
    }
}
