using CrestCore.Application;

namespace CrestCore.Contracts;

/// Stops a Space, and every Space of its group, offering to save passwords on
/// the website `Site` names, such as `example.com` or `*.example.com`, and
/// with `IncludesSubdomains` on every host under it; in place of `Replacing`
/// when a person edits an entry. Refused with `InvalidNeverSavedSite` when
/// `Site` names no website. Saved passwords still fill there.
public sealed record NeverSaveSite(Guid WorkspaceId, Guid SpaceId, string Site, bool IncludesSubdomains,
    NeverSavedSite? Replacing) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        var site = NeverSavedSite.Reading(Site, IncludesSubdomains) ?? throw new Rejected(new InvalidNeverSavedSite());
        var preferences = workspace.Editable(turn.Basis, SpaceId).Settings.CredentialPreferences;
        return new SetCredentialPreferences(WorkspaceId, SpaceId, preferences.NeverSaving(site, Replacing)).Edit(workspace, turn);
    }

    #endregion
}
