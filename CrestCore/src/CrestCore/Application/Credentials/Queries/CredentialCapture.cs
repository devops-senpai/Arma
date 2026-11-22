using CrestCore.Application;

namespace CrestCore.Contracts;

/// What one credential form observation does to the page's credential state.
/// `Hint` is the page's remembered username from an earlier login step and
/// `Pending` the submitted credential still waiting for a sign-in; neither
/// carries the username or the password. `Now` is in seconds since 1970.
/// `NeverSavedSites` are the page's Space's, where no save is offered.
public sealed record CredentialCapture(CredentialFormFacts Facts, CredentialUsernameHint? Hint,
    CredentialPendingCandidate? Pending, double Now, IReadOnlyList<NeverSavedSite>? NeverSavedSites = null)
    : Query<CredentialCaptureDecision> {
    #region Actions - Answering

    /// A submitted password on a page whose top-level site the Space never
    /// saves on is not captured, so it is never offered a save; the site's
    /// saved passwords still fill.
    internal override CredentialCaptureDecision Answer(CrestApp app) {
        var decision = Facts.Event.Decide(Facts, Hint, Pending, Now);
        bool neverSaves = NeverSavedSites?.Any(site => site.Covers(Facts.TopLevelOrigin.Host)) == true;
        return decision.Action == CredentialCaptureAction.CaptureCandidate && neverSaves
            ? CredentialCaptureDecision.For(CredentialCaptureAction.Ignore) : decision;
    }

    #endregion
}
