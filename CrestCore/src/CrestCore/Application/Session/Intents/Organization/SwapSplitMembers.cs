using CrestCore.Application;

namespace CrestCore.Contracts;

/// Swaps two members of one split: `TabId` takes `OtherTabId`'s place in the
/// member order and `OtherTabId` takes its, while every other card and the
/// split's shape stay where they are. Refused with `NotSplitPartners` for two
/// tabs that are not members of one split.
public sealed record SwapSplitMembers(Guid WorkspaceId, Guid SpaceId, Guid TabId, Guid OtherTabId) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) =>
        workspace.Organizing(turn.Basis, SpaceId, SyncStaging.Edit,
            edited => edited.SwapSplitMembers(TabId, OtherTabId, turn.Now));

    #endregion
}
