using CrestCore.Application;

namespace CrestCore.Contracts;

/// Lays the split `GroupId` out in `Shape` over its members' order, after
/// moving `TabId`, when one is named, to member `MemberIndex` as
/// `MoveSplitMember` moves it, all in one edit. Refused with
/// `UnknownSplitGroup` for a split of fewer than two tabs or a tab outside it,
/// and with `SplitShapeMismatch` for a shape whose leaves do not count its
/// members.
public sealed record ArrangeSplit(Guid WorkspaceId, Guid SpaceId, Guid GroupId, SplitShape Shape, Guid? TabId, int? MemberIndex)
    : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) =>
        workspace.Organizing(turn.Basis, SpaceId, SyncStaging.Edit,
            edited => edited.ArrangeSplit(GroupId, Shape, TabId, MemberIndex, turn.Now));

    #endregion
}
