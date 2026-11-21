using System.Text.Json.Nodes;

using CrestCore.Contracts;
using CrestCore.Domain;

namespace CrestCore.Application;

internal static partial class StoredSessionCodec {
    #region Actions - Split shapes

    /// The shape a split record keeps, or none: its `shape`, or, from a
    /// record an earlier Arma build wrote, its `layout` tree with each card's
    /// tab dropped, since that build kept the members in the order the tree
    /// read them.
    internal static SplitShape? DecodeSplitShape(JsonObject group) {
        ArgumentNullException.ThrowIfNull(group);
        if (group[Key.SplitShape] is { } shape) return DecodeSplitShape(Object(shape), depth: 0);
        return group[Key.LegacySplitLayout] is { } layout ? DecodeSplitShape(Object(layout), depth: 0) : null;
    }

    /// A shape: a leaf names no axis and no children, a branch names both.
    /// A branch with an axis this build cannot name, with fewer than two
    /// children, or a shape of more cards than a split holds, is unreadable.
    private static SplitShape DecodeSplitShape(JsonObject value, int depth) {
        if (value[Key.SplitAxis] is null && value[Key.SplitChildren] is null) return SplitShape.Leaf;
        var axis = SplitAxis.Named(Text(value[Key.SplitAxis])) ?? throw new BrowserRuleException(BrowserRule.InvalidSavedState);
        var children = Items(value[Key.SplitChildren]).Select(child => DecodeSplitShape(Object(child), depth + 1)).ToArray();
        var shape = SplitShape.Along(axis, children);
        if (children.Length < 2 || depth >= SplitGroupState.MaximumMembers
            || shape.LeafCount > SplitGroupState.MaximumMembers)
            throw new BrowserRuleException(BrowserRule.InvalidSavedState);
        return shape;
    }

    internal static JsonObject Encode(SplitShape shape) {
        ArgumentNullException.ThrowIfNull(shape);
        var value = new JsonObject();
        if (shape.Axis is not { } axis) return value;
        value[Key.SplitAxis] = axis.Name;
        value[Key.SplitChildren] = new JsonArray([.. shape.Children.Select(child => (JsonNode)Encode(child))]);
        return value;
    }

    #endregion
}
