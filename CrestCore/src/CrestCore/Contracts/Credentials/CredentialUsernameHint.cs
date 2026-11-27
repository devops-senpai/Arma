namespace CrestCore.Contracts;

/// The page's remembered username from an earlier step of a multi-step login,
/// without the username itself. `CapturedAt` is in seconds since 1970.
public sealed record CredentialUsernameHint(CredentialOrigin Origin, CredentialOrigin TopLevelOrigin, double CapturedAt) {
    #region Static Variables

    /// Seconds a username from one login step is kept for the next step.
    internal const double Lifetime = 5 * 60;

    #endregion

    #region Actions - Capture

    /// A remembered username applies, within its lifetime, to a later step of
    /// the same sign-in: a frame and a top-level page on the same scheme and
    /// the same registrable domains as the ones that produced it, so a site
    /// that asks for the username on `login.example.com` and the password on
    /// `auth.example.com` is one sign-in, while `alice.github.io` and
    /// `bob.github.io` are not.
    internal bool Applies(CredentialOrigin frameOrigin, CredentialOrigin topLevelOrigin, double now) =>
        Origin.Validated().IsSameSite(frameOrigin) && TopLevelOrigin.Validated().IsSameSite(topLevelOrigin)
        && CredentialPendingCandidate.Seconds(now) - CredentialPendingCandidate.Seconds(CapturedAt) <= Lifetime;

    #endregion
}
