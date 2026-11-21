import Foundation
import XCTest

@testable import Crest

/// "Fancy Move": when a ⇧⌘-held press picks a Split View card up, which slot
/// the gap it leaves is standing in, and how the row is drawn around it.
///
/// The gesture itself is a local `NSEvent` monitor no test can drive, which is
/// exactly why every decision it makes is a pure function. These are the
/// contract for those decisions.
final class BrowserSplitCardLiftTests: XCTestCase {

    // MARK: - Pickup

    /// Everything the ⇧⌘ pair is not. Plain ⌘-click still opens a link in a new
    /// tab, ⌥-click still downloads, ⌃-click is still a right-click, and adding
    /// a third modifier to ⇧⌘ hands the press back to the page rather than
    /// widening the carry's claim.
    func testEveryOtherModifierCombinationIsLeftToThePage() {
        XCTAssertFalse(Self.picksUp(modifiers: .command))
        XCTAssertFalse(Self.picksUp(modifiers: .shift))
        XCTAssertFalse(Self.picksUp(modifiers: .option))
        XCTAssertFalse(Self.picksUp(modifiers: .control))
        XCTAssertFalse(Self.picksUp(modifiers: [.command, .option]))
        XCTAssertFalse(Self.picksUp(modifiers: [.command, .shift, .option]))
        XCTAssertFalse(Self.picksUp(modifiers: [.command, .shift, .control]))
    }

    // MARK: - Divider proximity

    /// In a shape, the row divider between two stacked cards belongs to the
    /// resize, across the run where both cards stand, and the middle of the
    /// column they share does not, though the two are neighbours left to
    /// right.
    func testARowDividerInAShapeBelongsToTheResize() {
        let stacked = [
            CGRect(x: 0, y: 0, width: 300, height: 296),
            CGRect(x: 0, y: 304, width: 300, height: 296),
            CGRect(x: 308, y: 0, width: 300, height: 600),
        ]
        XCTAssertTrue(BrowserSplitCardLift.isOverTileDivider(CGPoint(x: 150, y: 300), cardFrames: stacked))
        XCTAssertTrue(BrowserSplitCardLift.isOverTileDivider(CGPoint(x: 304, y: 450), cardFrames: stacked))
        XCTAssertFalse(BrowserSplitCardLift.isOverTileDivider(CGPoint(x: 150, y: 150), cardFrames: stacked))
        XCTAssertFalse(BrowserSplitCardLift.isOverTileDivider(CGPoint(x: 450, y: 300), cardFrames: stacked))
    }

    // MARK: - The gap in two dimensions

    /// A row of columns aims as `SplitShape.columns`: onto a card's top edge
    /// stacks the carried card above it, beside a card keeps the row (no shape
    /// to store, so the release is Paul's member move), and onto a card's
    /// middle swaps the two.
    func testACarryOutOfColumnsStacksMovesOrSwaps() {
        let members = BrowserSplitCardTestFixture.members.map(\.id)
        let frames = Self.registeredFrames(count: 3)
        let leaf = SplitShape.leaf
        func gap(atX x: CGFloat, y: CGFloat) -> (memberIndex: Int, shape: SplitShape?, swapsWith: UUID?)? {
            BrowserSplitCardLift.shapedGap(
                at: CGPoint(x: x, y: y), members: members, lifted: members[0], shape: .columns(3),
                cardFrames: frames, rightToLeft: false)
        }

        let stacked = gap(atX: 458, y: 100)
        XCTAssertEqual(stacked?.memberIndex, 0)
        XCTAssertEqual(stacked?.shape, .along(.horizontal, [.along(.vertical, [leaf, leaf]), leaf]))
        XCTAssertNil(stacked?.swapsWith)

        let moved = gap(atX: 850, y: 300)
        XCTAssertEqual(moved?.memberIndex, 2)
        XCTAssertNil(moved?.shape)
        XCTAssertNil(moved?.swapsWith)

        let swapped = gap(atX: 766, y: 300)
        XCTAssertEqual(swapped?.memberIndex, 2)
        XCTAssertNil(swapped?.shape)
        XCTAssertEqual(swapped?.swapsWith, BrowserSplitCardTestFixture.trailingTabID)

        // The row drops the carried card's frame while it draws the gap, and
        // the aim must not fall back to the row's slot for that.
        var unregistered = frames
        unregistered[members[0]] = nil
        let aimed = BrowserSplitCardLift.shapedGap(
            at: CGPoint(x: 458, y: 100), members: members, lifted: members[0], shape: .columns(3),
            cardFrames: unregistered, rightToLeft: false)
        XCTAssertEqual(aimed?.memberIndex, stacked?.memberIndex)
        XCTAssertEqual(aimed?.shape, stacked?.shape)
    }

    // MARK: - Fixtures

    private static func picksUp(
        modifiers: BrowserKeyboardModifierFlags = [.command, .shift],
        isInsideCard: Bool = true,
        isOverDivider: Bool = false,
        memberCount: Int = 2,
        isDraggingSidebarItem: Bool = false,
        isCommandPalettePresented: Bool = false
    ) -> Bool {
        BrowserSplitCardLift.picksUp(
            modifiers: modifiers,
            isInsideCard: isInsideCard,
            isOverDivider: isOverDivider,
            memberCount: memberCount,
            isDraggingSidebarItem: isDraggingSidebarItem,
            isCommandPalettePresented: isCommandPalettePresented
        )
    }

    private static func registeredFrames(count: Int) -> [UUID: CGRect] {
        registeredFrames(
            members: Array(BrowserSplitCardTestFixture.members.prefix(count)),
            widths: Array(repeating: 300, count: count)
        )
    }

    /// Card frames as the row would register them for `members` in the order
    /// given: the first member in the leading column, and so on.
    private static func registeredFrames(
        members: [BrowserSplitCardTestFixture.Member],
        widths: [CGFloat]
    ) -> [UUID: CGRect] {
        Dictionary(
            uniqueKeysWithValues: zip(members.map(\.id), frames(widths: widths))
        )
    }

    private static func frames(widths: [CGFloat]) -> [CGRect] {
        let gap = BrowserSplitLayoutMetrics.interCardGap
        var origin: CGFloat = 0
        var frames: [CGRect] = []
        for width in widths {
            frames.append(CGRect(x: origin, y: 0, width: width, height: 600))
            origin += width + gap
        }
        return frames
    }

}

private enum BrowserSplitCardTestFixture {
    static let leadingTabID = tabID(0x11)
    static let middleTabID = tabID(0x12)
    static let trailingTabID = tabID(0x13)

    static let members = [
        member(id: leadingTabID, title: "Release Notes"),
        member(id: middleTabID, title: "Layout Research"),
        member(id: trailingTabID, title: "Split View Spec"),
    ]

    /// A card of the row: only its identity matters to the lift.
    struct Member: Identifiable, Equatable {
        let id: UUID
        let title: String
    }

    private static func member(id: UUID, title: String) -> Member {
        Member(id: id, title: title)
    }

    private static func tabID(_ finalByte: UInt8) -> UUID {
        uuid(finalByte)
    }

    private static func uuid(_ finalByte: UInt8) -> UUID {
        UUID(
            uuid: (
                0x43, 0x52, 0x45, 0x53,
                0x54, 0x54,
                0x45, 0x53,
                0x54, 0x53,
                0x50, 0x4C, 0x49, 0x54, 0x00, finalByte
            ))
    }
}
