using CrestCore.Application;
using CrestCore.Domain;

namespace CrestCore.Contracts;

/// Drops a split member lifted alone onto the middle of the card that shows
/// `TabId`, another member of its split, swapping the two as
/// `SwapSplitMembers` does. Refused with `NotSplitPartners` for a lift of
/// more than one tab, or a tab outside that split.
public sealed record DropOntoSplitCard(Guid WorkspaceId, Guid WindowId, Guid SpaceId, TabSelection Selection, Guid TabId)
    : SidebarDrop(WorkspaceId, WindowId, SpaceId, Selection) {
    #region Actions - Session

    internal override SessionIntent Committed(NativeSessionAuthority.Lift lift, IIdSource ids) =>
        lift.Alone is { } tab
            ? new SwapSplitMembers(WorkspaceId, SpaceId, tab.Id, TabId)
            : throw new Rejected(new NotSplitPartners(TabId, TabId));

    #endregion
}
