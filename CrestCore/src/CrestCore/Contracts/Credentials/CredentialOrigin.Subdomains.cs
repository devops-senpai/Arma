using CrestCore.Domain;

namespace CrestCore.Contracts;

public sealed partial record CredentialOrigin {
    #region Actions - Subdomains

    /// Whether a password saved for this origin, reaching its subdomains,
    /// fills a page at `page`: the same scheme and port, and a host under this
    /// one. A public suffix such as `github.io`, whose subdomains belong to
    /// different people, reaches none, nor does an IP address.
    internal bool FillsSubdomain(CredentialOrigin page) {
        ArgumentNullException.ThrowIfNull(page);
        if (Scheme != page.Scheme || Port != page.Port) return false;
        string host = CanonicalHost(Host) ?? Host;
        if (host.Contains(':', StringComparison.Ordinal) || CanonicalHost(host) != host || host.Split('.').All(label => label.All(char.IsAsciiDigit)))
            return false;
        return page.Host.EndsWith("." + host, StringComparison.Ordinal) && !SiteDomain.IsListedPublicSuffix(host);
    }

    /// Whether this origin and `other` are the same site: the same scheme
    /// and registrable domain, such as `https://login.example.com` and
    /// `https://auth.example.com`.
    internal bool IsSameSite(CredentialOrigin other) {
        ArgumentNullException.ThrowIfNull(other);
        return Scheme == other.Scheme && SiteDomain.AreSameSite(Host, other.Host);
    }

    #endregion
}
