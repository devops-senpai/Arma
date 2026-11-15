using CrestCore.Application;
using CrestCore.Domain;

namespace CrestCore.Contracts;

/// Whether a password saved for `Origin` may also fill the hosts under it.
/// Refused with `SubdomainsOfPublicSuffix` for a public suffix such as
/// `github.io`, whose subdomains belong to different people; an IP address
/// has no subdomains to reach.
public sealed record CredentialSubdomainReach(CredentialOrigin Origin) : Query<CredentialFillDecision> {
    #region Actions - Answering

    internal override CredentialFillDecision Answer(CrestApp app) {
        var origin = Origin.Validated();
        if (PublicSuffixList.IsPublicSuffix(origin.Host)) throw new Rejected(new SubdomainsOfPublicSuffix(origin.Host));
        return new(origin.FillsSubdomain(origin with { Host = "a." + origin.Host }));
    }

    #endregion
}
