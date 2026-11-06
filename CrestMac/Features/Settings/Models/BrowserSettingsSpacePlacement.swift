import Foundation

/// What letting go of a Space dragged over Settings' list of Spaces does at
/// one place in it, as a tab lands among folders: on another group's row, or
/// among its Sub-Spaces, the Space asks to join that group; among its own
/// group's Sub-Spaces it moves there; and between groups a Sub-Space asks to
/// come out on its own while a group moves whole.
@MainActor
struct BrowserSettingsSpacePlacement {
    // MARK: - Variables

    /// The group the Space would join, by its primary, whose rows all show
    /// it.
    let joinedGroupID: UUID?
    /// The row the Space would stand before, or the count of rows for after
    /// the last; nil when it joins a group instead.
    let insertionIndex: Int?
    private let landing: @MainActor () -> BrowserSpaceGroupChange?

    // MARK: - Initializers

    private init(
        joinedGroupID: UUID? = nil, insertionIndex: Int? = nil,
        landing: @escaping @MainActor () -> BrowserSpaceGroupChange?
    ) {
        self.joinedGroupID = joinedGroupID
        self.insertionIndex = insertionIndex
        self.landing = landing
    }

    /// The placement of `space` held at `aim` among `spaces`, the list's rows
    /// in order; nil where letting go would change nothing.
    init?(
        of space: SpaceModel, at aim: BrowserSettingsSpaceDrag.Aim, among spaces: [SpaceModel],
        in browser: BrowserStore
    ) {
        if let row = aim.row, spaces.indices.contains(row),
            let joining = Self.joining(space, groupOf: spaces[row], in: browser)
        {
            self = joining
        } else if let standing = Self.standing(space, before: aim.gap, among: spaces, in: browser) {
            self = standing
        } else {
            return nil
        }
    }

    // MARK: - Actions - Landing

    /// Lands the Space. Answers the change to confirm first, when landing
    /// there is one.
    func land() -> BrowserSpaceGroupChange? {
        landing()
    }

    // MARK: - Actions - Resolving

    /// `space` asking to join the group `member` belongs to; nil when it may
    /// not join it.
    private static func joining(
        _ space: SpaceModel, groupOf member: SpaceModel, in browser: BrowserStore
    ) -> BrowserSettingsSpacePlacement? {
        guard let change = BrowserSpaceGroupChange.joining(space, into: member, in: browser) else { return nil }
        return BrowserSettingsSpacePlacement(joinedGroupID: browser.primary(of: member).id) { change }
    }

    /// `space` standing before the row at `index` of `spaces`; nil when it
    /// already stands there or may not.
    private static func standing(
        _ space: SpaceModel, before index: Int, among spaces: [SpaceModel], in browser: BrowserStore
    ) -> BrowserSettingsSpacePlacement? {
        let next = spaces.indices.contains(index) ? spaces[index] : nil
        if let next, browser.isSubSpace(next) {
            guard browser.isSubSpace(space), browser.primary(of: space) === browser.primary(of: next) else {
                return joining(space, groupOf: next, in: browser)
            }
            // Among its own group's Sub-Spaces, where it does not stand yet.
            guard next !== space, index == 0 || spaces[index - 1] !== space else { return nil }
            return BrowserSettingsSpacePlacement(insertionIndex: index) {
                browser.move(space.id, before: next.id)
                return nil
            }
        }
        if let change = BrowserSpaceGroupChange.separating(space, in: browser) {
            return BrowserSettingsSpacePlacement(insertionIndex: index) { change }
        }
        // The Space's whole group moves, unless the gap is inside it or beside it.
        let members = browser.groupMembers(of: space)
        guard let first = spaces.firstIndex(where: { $0 === members.first }),
            let last = spaces.lastIndex(where: { $0 === members.last }),
            index < first || index > last + 1
        else { return nil }
        return BrowserSettingsSpacePlacement(insertionIndex: index) {
            browser.moveGroup(of: space.id, before: next?.id)
            return nil
        }
    }
}
