using System.Globalization;

namespace CrestCore.Contracts;

/// A website a Space never offers to save passwords on: `Host`, and with
/// `IncludesSubdomains` every host under it too, so `example.com` with
/// subdomains covers `accounts.example.com` while `foo.example.com` alone
/// leaves `bar.example.com` offering. Saved passwords still fill there.
public sealed record NeverSavedSite(string Host, bool IncludesSubdomains) {
    #region Actions - Reading

    /// The site a person names in `text`, such as `example.com`,
    /// `https://Example.com/login` or `*.example.com`, which last includes
    /// its subdomains whatever `includesSubdomains` says; nil when the text
    /// names no host.
    public static NeverSavedSite? Reading(string text, bool includesSubdomains) {
        ArgumentNullException.ThrowIfNull(text);
        var trimmed = text.Trim();
        var wildcard = trimmed.StartsWith("*.", StringComparison.Ordinal);
        if (wildcard) trimmed = trimmed[2..];
        if (trimmed.Length == 0 || trimmed.Contains('*', StringComparison.Ordinal)) return null;
        var address = trimmed.Contains("://", StringComparison.Ordinal) ? trimmed : "https://" + trimmed;
        if (!Uri.TryCreate(address, UriKind.Absolute, out var uri)
            || uri.HostNameType is not (UriHostNameType.Dns or UriHostNameType.IPv4 or UriHostNameType.IPv6))
            return null;
        var host = Normalized(uri.IdnHost);
        return host.Length == 0 ? null : new(host, includesSubdomains || wildcard);
    }

    /// The site of a page at `host`, alone.
    public static NeverSavedSite? OfPage(string host) => Reading(host, includesSubdomains: false);

    #endregion

    #region Actions - Matching

    /// Whether a page at `host` is this site.
    public bool Covers(string host) {
        ArgumentNullException.ThrowIfNull(host);
        var candidate = Normalized(host);
        return candidate == Host
            || IncludesSubdomains && candidate.EndsWith("." + Host, StringComparison.Ordinal);
    }

    /// Whether this site and `other` name the same host, whatever each says
    /// about subdomains, so a Space keeps one entry per host.
    internal bool NamesSameHost(NeverSavedSite other) => other.Host == Host;

    private static string Normalized(string host) => host.Trim().TrimEnd('.').ToLower(CultureInfo.InvariantCulture);

    #endregion
}

/// The website a person named for a Space never to save passwords on is not
/// one Crest can read.
public sealed record InvalidNeverSavedSite() : Rejection {
    #region Variables

    /// What the site list tells the person.
    [Localized]
    public string Message => "Enter a website, such as example.com or *.example.com.";

    #endregion
}
