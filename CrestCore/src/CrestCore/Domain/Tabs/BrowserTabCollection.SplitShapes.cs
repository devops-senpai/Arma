using CrestCore.Contracts;

namespace CrestCore.Domain;

public sealed partial class BrowserTabCollection {
    #region Actions - Split shapes

    /// The shape a split's run of tabs renders in, or null for one row of
    /// columns: the shape it keeps, while its leaves count the run. A record
    /// that counts more or fewer stays as it was kept, since the rest of a
    /// sync batch may not have arrived.
    public SplitShape? ShapeOf(Guid group) {
        var shape = splitGroups.FirstOrDefault(candidate => candidate.Id == group)?.Shape;
        return shape is not null && shape.LeafCount == Run(group).Count ? shape : null;
    }

    /// Lays the split's run of tabs out in `shape`, chosen now. Refused with
    /// `UnknownSplitGroup` for a split of fewer than two tabs, and with
    /// `SplitShapeMismatch` for a shape whose leaves do not count them.
    public void Shape(Guid group, SplitShape shape, DateTimeOffset now) {
        ArgumentNullException.ThrowIfNull(shape);
        int members = Run(group).Count;
        if (members < SplitGroupState.MinimumShownMembers) throw new Rejected(new UnknownSplitGroup(group));
        if (shape.LeafCount != members) throw new Rejected(new SplitShapeMismatch(group, shape.LeafCount));
        Keep(group, shape, now);
    }

    /// Moves `tabId`, when one is named, to member `memberIndex` of the split
    /// as `MoveSplitMember` moves it, and lays the split out in `shape`, as
    /// one edit: a card carried to another tile is a move in member order
    /// and the shape that tile belongs to.
    public void ArrangeSplit(Guid group, SplitShape shape, Guid? tabId, int? memberIndex, DateTimeOffset now) {
        ArgumentNullException.ThrowIfNull(shape);
        if (shape.LeafCount != Run(group).Count) throw new Rejected(new SplitShapeMismatch(group, shape.LeafCount));
        if (tabId is { } moved && memberIndex is { } index) {
            if (Tab(moved).SplitGroupId != group) throw new Rejected(new UnknownSplitGroup(group));
            MoveSplitMember(moved, index, now);
        }
        Shape(group, shape, now);
    }

    /// Swaps two members of one split, each into the other's place in the
    /// member order, as two of `MoveSplitMember`'s moves: the first takes the
    /// second's index, which slides the second one place toward it, and the
    /// second then takes the first's old index. Every other card keeps its
    /// tile, and the shape is untouched. Refused with `NotSplitPartners` for
    /// a tab named twice or two tabs outside one split.
    public void SwapSplitMembers(Guid id, Guid otherId, DateTimeOffset now) {
        var members = SplitMembers(id).Select(tab => tab.Id).ToList();
        int from = members.IndexOf(id), to = members.IndexOf(otherId);
        if (id == otherId || members.Count < 2 || to < 0) throw new Rejected(new NotSplitPartners(id, otherId));
        MoveSplitMember(id, to, now);
        MoveSplitMember(otherId, from, now);
    }

    /// The split `tab` is leaving keeps the shape it shows without the tab's
    /// card; one that shows as columns stays columns.
    private void ShapeLeaving(BrowserTab tab, DateTimeOffset now) {
        if (tab.SplitGroupId is not { } group) return;
        Keep(group, ShapeOf(group)?.Removing(Run(group).IndexOf(tab)), now);
    }

    /// Keeps `shape` as the split's, chosen now. A split with no record gets
    /// one only for a shape that is not columns.
    private void Keep(Guid group, SplitShape? shape, DateTimeOffset now) {
        int index = splitGroups.FindIndex(candidate => candidate.Id == group);
        var current = index < 0 ? new SplitGroupState(group) : splitGroups[index];
        var kept = current.WithShape(shape, now);
        if (kept == current) return;
        if (index < 0) splitGroups.Add(kept);
        else splitGroups[index] = kept;
    }

    /// The split's first run of tabs, in order.
    private List<BrowserTab> Run(Guid group) {
        int first = tabs.FindIndex(tab => tab.SplitGroupId == group);
        return first < 0 ? [] : [.. tabs.Skip(first).TakeWhile(tab => tab.SplitGroupId == group)];
    }

    #endregion
}
