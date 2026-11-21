namespace CrestCore.Contracts;

/// <summary>
/// How a split's cards tile a window, laid over the order its members already keep:
/// a leaf is one card, and a branch lays its <see cref="Children"/> out along
/// <see cref="Axis"/>. Leaves name no tab. Reading them in order visits the members
/// in order, so the first leaf is the first member and moving a member is moving
/// which card fills a leaf. A split without a shape, or with one whose leaves do not
/// count its members, is one row of columns.
/// </summary>
public sealed record SplitShape(SplitAxis? Axis, IReadOnlyList<SplitShape> Children) {
    #region Static Variables

    /// One card.
    internal static readonly SplitShape Leaf = new(null, []);

    #endregion

    #region Variables

    public IReadOnlyList<SplitShape> Children {
        get;
        init => field = [.. value];
    } = [.. Children];

    /// The shape is one card.
    public bool IsLeaf => Axis is null;

    /// How many cards the shape lays out.
    public int LeafCount => IsLeaf ? 1 : Children.Sum(child => child.LeafCount);

    /// Whether the shape is one row of columns, which a split keeps as no
    /// shape at all.
    public bool IsColumns => Axis == SplitAxis.Horizontal && Children.All(child => child.IsLeaf);

    #endregion

    #region Actions - Making

    public static SplitShape Along(SplitAxis axis, IEnumerable<SplitShape> children) => new(axis, [.. children]);

    /// One row of `count` columns.
    public static SplitShape Columns(int count) => Along(SplitAxis.Horizontal, Enumerable.Repeat(Leaf, count));

    #endregion

    #region Actions - Editing

    /// The shape with a card landed on `side` of leaf `leaf`: beside it in the
    /// branch that already runs that way, or in a new branch that takes the
    /// leaf's place. The new card reads as leaf `leaf` before the card it
    /// lands beside and `leaf + 1` after it; a leaf the shape does not have
    /// lands the card outside the whole shape instead.
    public SplitShape Inserting(int leaf, SplitSide side) {
        ArgumentNullException.ThrowIfNull(side);
        if (IsLeaf) return InsertingOutside(side);
        int first = 0;
        var children = Children.ToList();
        for (int index = 0; index < children.Count; index++) {
            int count = children[index].LeafCount;
            if (leaf >= first && leaf < first + count) {
                if (children[index].IsLeaf && Axis == side.Axis) children.Insert(side.IsAfter ? index + 1 : index, Leaf);
                else children[index] = children[index].Inserting(leaf - first, side);
                return this with { Children = children };
            }
            first += count;
        }
        return InsertingOutside(side);
    }

    /// The shape with a card landed on `side` of the whole of it, the full
    /// height or width of the split.
    public SplitShape InsertingOutside(SplitSide side) {
        ArgumentNullException.ThrowIfNull(side);
        return Along(side.Axis, side.IsAfter ? [this, Leaf] : [Leaf, this]).Normalized();
    }

    /// The shape without leaf `leaf`, every branch it empties closed; null
    /// for a shape that held no other card.
    public SplitShape? Removing(int leaf) => Pruned(leaf, 0).Shape;

    /// The shape with every branch of one child given way to it, and every
    /// branch inside one that runs the same way merged into it.
    public SplitShape Normalized() => Pruned(-1, 0).Shape ?? Leaf;

    /// The shape from leaf `first` on without leaf `removed`, normalized, and
    /// the leaf after its last.
    private (SplitShape? Shape, int Next) Pruned(int removed, int first) {
        if (IsLeaf) return (first == removed ? null : this, first + 1);
        var children = new List<SplitShape>();
        int next = first;
        foreach (var child in Children) {
            (var kept, next) = child.Pruned(removed, next);
            if (kept is null) continue;
            if (!kept.IsLeaf && kept.Axis == Axis) children.AddRange(kept.Children);
            else children.Add(kept);
        }
        var shape = children.Count switch {
            0 => null,
            1 => children[0],
            _ => this with { Children = children }
        };
        return (shape, next);
    }

    #endregion

    #region Actions - Branches

    /// The id a window keeps a branch's shares under, for a split `groupId`
    /// shaped like this: the split's own for the outermost branch, so a row
    /// of columns keeps the shares it always kept, and for a branch inside it
    /// one derived from the split's and the branch's `path` of child indices.
    /// Every device derives the same id, and only the last eight bytes change,
    /// which read the same on every platform.
    public static Guid BranchId(Guid groupId, IReadOnlyList<int> path) {
        ArgumentNullException.ThrowIfNull(path);
        if (path.Count == 0) return groupId;
        var bytes = groupId.ToByteArray();
        for (int depth = 0; depth < path.Count; depth++) bytes[15 - depth] ^= (byte)(0x80 | (path[depth] + 1));
        return new Guid(bytes);
    }

    /// How many children the branch a window keeps shares for as `branchId`
    /// lays out, in a split `groupId` shaped like this; null for no such
    /// branch.
    public int? ChildCount(Guid groupId, Guid branchId) =>
        Branches([]).FirstOrDefault(branch => BranchId(groupId, branch.Path) == branchId).Branch?.Children.Count;

    /// Every branch of the shape, this one first, each with its path from it.
    private IEnumerable<(IReadOnlyList<int> Path, SplitShape? Branch)> Branches(IReadOnlyList<int> path) =>
        IsLeaf ? [] : [(path, this), .. Children.SelectMany((child, index) => child.Branches([.. path, index]))];

    #endregion

    #region Actions - Equality

    public bool Equals(SplitShape? other) => other is not null && Axis == other.Axis && Children.SequenceEqual(other.Children);

    public override int GetHashCode() => HashCode.Combine(Axis, LeafCount);

    #endregion
}
