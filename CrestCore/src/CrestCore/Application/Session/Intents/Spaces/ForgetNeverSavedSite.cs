using CrestCore.Application;

namespace CrestCore.Contracts;

/// Lets a Space, and every Space of its group, offer to save passwords on
/// `Site` again.
public sealed record ForgetNeverSavedSite(Guid WorkspaceId, Guid SpaceId, NeverSavedSite Site) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        var preferences = workspace.Editable(turn.Basis, SpaceId).Settings.CredentialPreferences;
        return new SetCredentialPreferences(WorkspaceId, SpaceId, preferences.Forgetting(Site)).Edit(workspace, turn);
    }

    #endregion
}
