using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;
using CrestCore.Domain;

using Xunit;

namespace CrestCore.Tests;

public sealed class SplitShapeContractsTests {
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-11-15T12:00:00Z");
    private static readonly SplitShape Leaf = SplitShape.Leaf;
    private static SplitShape Across(params SplitShape[] children) => SplitShape.Along(SplitAxis.Horizontal, children);
    private static SplitShape Down(params SplitShape[] children) => SplitShape.Along(SplitAxis.Vertical, children);
    private static TabState Tab(string title) => new(Guid.NewGuid(), title, "https://example.com/" + title, null, null, "globe", null, null,
        null, TabPlacement.Current, null, null, Now, null, null, null, false);
    private static BrowserTabCollection Space(params TabState[] tabs) => BrowserTabCollection.Restore(tabs, [], []);
    private static string[] Titles(BrowserTabCollection space, Guid member) => [.. space.SplitMembers(member).Select(tab => tab.Title)];
    private static Guid Group(BrowserTabCollection space, Guid member) => space.Tab(member).SplitGroupId!.Value;

    [Fact]
    public void InsertingRemovingAndNormalizingKeepTheLeavesInReadingOrder() {
        var stacked = Leaf.Inserting(0, SplitSide.Below);
        Assert.Equal(Down(Leaf, Leaf), stacked);

        // Beside a leaf across a stack, a new row opens around it; along the
        // stack, the new card joins it; outside, it takes the full height.
        Assert.Equal(Down(Across(Leaf, Leaf), Leaf), stacked.Inserting(0, SplitSide.Trailing));
        Assert.Equal(Down(Leaf, Leaf, Leaf), stacked.Inserting(1, SplitSide.Below));
        var tiled = stacked.InsertingOutside(SplitSide.Trailing);
        Assert.Equal(Across(Down(Leaf, Leaf), Leaf), tiled);
        Assert.Equal(Across(Down(Leaf, Leaf), Leaf, Leaf), tiled.InsertingOutside(SplitSide.Trailing));
        Assert.Equal(3, tiled.LeafCount);

        // A branch left with one child gives way to it, and one inside a
        // branch that runs the same way merges into it.
        Assert.Equal(Across(Leaf, Leaf), tiled.Removing(0));
        Assert.True(tiled.Removing(0)!.IsColumns);
        Assert.Null(Leaf.Removing(0));
        Assert.Equal(Across(Leaf, Leaf, Leaf), Across(Leaf, Across(Leaf, Leaf)).Normalized());
        Assert.Equal(Leaf, Across(Down(Leaf)).Normalized());

        // Each branch keeps its shares under an id of its own; the outer one
        // under the split's.
        var group = Guid.NewGuid();
        Assert.Equal(2, tiled.ChildCount(group, group));
        var inner = SplitShape.BranchId(group, [0]);
        Assert.NotEqual(group, inner);
        Assert.NotEqual(inner, SplitShape.BranchId(group, [1]));
        Assert.Equal(2, tiled.ChildCount(group, inner));
        Assert.Null(tiled.ChildCount(group, SplitShape.BranchId(group, [1])));
    }

    [Fact]
    public void JoiningWithAShapeTilesTheSplitAndLeavingKeepsTheShapeWithoutTheCard() {
        var a = Tab("a"); var b = Tab("b"); var c = Tab("c");
        var space = Space(a, b, c);
        var ids = new SystemIdSource();

        space.JoinSplit(b.Id, a.Id, 1, ids, Now);
        space.Shape(Group(space, a.Id), Down(Leaf, Leaf), Now);
        space.JoinSplit(c.Id, a.Id, 2, ids, Now.AddMinutes(1));
        // The shape counts two cards and the split now holds three, so it
        // shows as columns and the record stays as it was kept.
        Assert.Null(space.ShapeOf(Group(space, a.Id)));
        Assert.Equal(Down(Leaf, Leaf), space.SplitGroups.Single().Shape);
        Assert.IsType<SplitShapeMismatch>(Assert.Throws<Rejected>(() =>
            space.Shape(Group(space, a.Id), Down(Leaf, Leaf), Now)).Rejection);

        var tiled = Across(Down(Leaf, Leaf), Leaf);
        space.Shape(Group(space, a.Id), tiled, Now.AddMinutes(2));
        Assert.Equal(tiled, space.ShapeOf(Group(space, a.Id)));
        Assert.Equal(Now.AddMinutes(2), space.SplitGroups.Single().ShapeModifiedAt);

        space.LeaveSplit(a.Id, Now.AddMinutes(3));
        Assert.Equal(["b", "c"], Titles(space, b.Id));
        Assert.Null(space.ShapeOf(Group(space, b.Id)));
        Assert.Null(space.SplitGroups.Single().Shape);
    }

    [Fact]
    public void ArrangingLaysTheMembersOutAndMovesTheCarriedCardInTheSameEdit() {
        var a = Tab("a"); var b = Tab("b"); var c = Tab("c"); var d = Tab("d");
        var space = Space(a, b, c, d);
        var ids = new SystemIdSource();
        space.JoinSplit(b.Id, a.Id, 1, ids, Now);
        space.JoinSplit(c.Id, a.Id, 2, ids, Now);
        space.JoinSplit(d.Id, a.Id, 3, ids, Now);
        var group = Group(space, a.Id);

        var grid = Down(Across(Leaf, Leaf), Across(Leaf, Leaf));
        space.ArrangeSplit(group, grid, null, null, Now.AddMinutes(1));
        Assert.Equal(grid, space.ShapeOf(group));
        Assert.Equal(["a", "b", "c", "d"], Titles(space, a.Id));

        // A card carried to the full-height tile on the right is a move in
        // member order and the shape that tile belongs to.
        var beside = Across(Down(Leaf, Leaf, Leaf), Leaf);
        space.ArrangeSplit(group, beside, a.Id, 3, Now.AddMinutes(2));
        Assert.Equal(["b", "c", "d", "a"], Titles(space, a.Id));
        Assert.Equal(beside, space.ShapeOf(group));

        // Columns are kept as no shape at all.
        space.ArrangeSplit(group, SplitShape.Columns(4), null, null, Now.AddMinutes(3));
        Assert.Null(space.SplitGroups.Single().Shape);
        Assert.Equal(Now.AddMinutes(3), space.SplitGroups.Single().ShapeModifiedAt);
        Assert.IsType<SplitShapeMismatch>(Assert.Throws<Rejected>(() =>
            space.ArrangeSplit(group, Down(Leaf, Leaf), a.Id, 0, Now.AddMinutes(4))).Rejection);
        Assert.Equal(["b", "c", "d", "a"], Titles(space, a.Id));
    }

    [Fact]
    public void SwappingTwoCardsKeepsTheShapeAndEveryOtherCard() {
        var a = Tab("a"); var b = Tab("b"); var c = Tab("c"); var d = Tab("d"); var e = Tab("e");
        var space = Space(a, b, c, d, e);
        var ids = new SystemIdSource();
        space.JoinSplit(b.Id, a.Id, 1, ids, Now);
        space.JoinSplit(c.Id, a.Id, 2, ids, Now);
        space.JoinSplit(d.Id, a.Id, 3, ids, Now);
        var group = Group(space, a.Id);
        var grid = Down(Across(Leaf, Leaf), Across(Leaf, Leaf));
        space.Shape(group, grid, Now);

        // A move would slide b and c along; a swap trades a and d alone.
        space.SwapSplitMembers(a.Id, d.Id, Now.AddMinutes(1));
        Assert.Equal(["d", "b", "c", "a"], Titles(space, a.Id));
        space.SwapSplitMembers(c.Id, b.Id, Now.AddMinutes(2));
        Assert.Equal(["d", "c", "b", "a"], Titles(space, a.Id));
        Assert.Equal(grid, space.ShapeOf(group));
        Assert.Equal(Now, space.SplitGroups.Single().ShapeModifiedAt);

        Assert.IsType<NotSplitPartners>(Assert.Throws<Rejected>(() =>
            space.SwapSplitMembers(a.Id, e.Id, Now)).Rejection);
        Assert.IsType<NotSplitPartners>(Assert.Throws<Rejected>(() =>
            space.SwapSplitMembers(a.Id, a.Id, Now)).Rejection);
    }

    [Fact]
    public void AShapeThatDoesNotCountTheMembersRendersAsColumns() {
        var group = new SplitGroupState(Guid.NewGuid(), Shape: Across(Down(Leaf, Leaf), Leaf), ShapeModifiedAt: Now);
        var inner = SplitShape.BranchId(group.Id, [0]);

        Assert.Equal(2, group.RenderedChildren(group.Id, members: 3));
        Assert.Equal(2, group.RenderedChildren(inner, members: 3));
        Assert.Equal(4, group.RenderedChildren(group.Id, members: 4));
        Assert.Equal(0, group.RenderedChildren(inner, members: 4));
        Assert.Equal(2, new SplitGroupState(group.Id).RenderedChildren(group.Id, members: 2));
    }

    [Fact]
    public void ShapesMergeOnTheirOwnClock() {
        var id = Guid.NewGuid();
        var stacked = new SplitGroupState(id, CustomTitle: "Later", TitleModifiedAt: Now.AddMinutes(1), Shape: Down(Leaf, Leaf),
            ShapeModifiedAt: Now);
        var tiled = new SplitGroupState(id, CustomTitle: "Earlier", TitleModifiedAt: Now, Shape: Across(Down(Leaf, Leaf), Leaf),
            ShapeModifiedAt: Now.AddMinutes(1));

        var merged = SplitGroupState.Merged([stacked, tiled]).Single();
        Assert.Equal("Later", merged.CustomTitle);
        Assert.Equal(tiled.Shape, merged.Shape);
        Assert.Equal(Now.AddMinutes(1), merged.ShapeModifiedAt);
        Assert.Equal(tiled.Shape, SplitGroupState.Merged([tiled, stacked]).Single().Shape);
    }

    [Fact]
    public void ShapesSurviveTheStoredSessionAndTheSyncedRecordAndReadAnEarlierLayout() {
        var shape = Across(Down(Leaf, Leaf), Leaf);
        var group = new SplitGroupState(Guid.NewGuid(), Shape: shape, ShapeModifiedAt: Now);

        Assert.Equal(group, StoredSessionCodec.DecodeSplitGroup(StoredSessionCodec.Encode(group)));
        foreach (var form in SyncPayloadForm.All) {
            var payload = SplitGroupPayload.Normalized(new JsonArray(StoredSessionCodec.Encode(group)), form).Single();
            Assert.Equal(shape, payload.Shape);
            Assert.Equal(shape, SplitGroupPayload.Normalized(new JsonArray(payload.Encode(form)), form).Single().Shape);
        }

        // An earlier Arma build kept a tree that named each card's tab; the
        // tree reads as the shape it tiled, under its clock.
        static JsonObject Card() => new() { ["id"] = new JsonObject { ["rawValue"] = Guid.NewGuid().ToString() } };
        var layout = new JsonObject {
            ["id"] = Guid.NewGuid().ToString(),
            ["axis"] = "horizontal",
            ["children"] = new JsonArray(
                new JsonObject { ["id"] = Guid.NewGuid().ToString(), ["axis"] = "vertical", ["children"] = new JsonArray(Card(), Card()) },
                Card())
        };
        var legacy = StoredSessionCodec.Encode(new SplitGroupState(group.Id));
        legacy["layout"] = layout;
        legacy["layoutModifiedAt"] = StoredSessionCodec.Encode(group)["shapeModifiedAt"]!.DeepClone();
        Assert.Equal(group, StoredSessionCodec.DecodeSplitGroup(legacy));
        Assert.False(StoredSessionCodec.Encode(StoredSessionCodec.DecodeSplitGroup(legacy)).ContainsKey("layout"));
        foreach (var form in SyncPayloadForm.All)
            Assert.Equal(shape, SplitGroupPayload.Normalized(new JsonArray(legacy.DeepClone()), form).Single().Shape);
    }
}
