using CrestCore.Application;

namespace CrestCore.Contracts;

/// Whether showing or copying a saved password asks the person to
/// authenticate now, by the Space's `Authentication` choice, given how many
/// seconds ago they last did for the Space, or null when they have not since
/// the device last slept or locked.
public sealed record CredentialAuthenticationCheck(CredentialAuthentication Authentication, double? SecondsSinceLastAuthenticated)
    : Query<CredentialAuthenticationDecision> {
    #region Actions - Answering

    internal override CredentialAuthenticationDecision Answer(CrestApp app) {
        return new(Authentication.Asks(SecondsSinceLastAuthenticated));
    }

    #endregion
}

/// Whether showing or copying a saved password asks to authenticate first.
public sealed record CredentialAuthenticationDecision(bool Asks);
