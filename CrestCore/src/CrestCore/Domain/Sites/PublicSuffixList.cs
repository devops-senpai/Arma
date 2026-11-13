using System.Globalization;
using System.Reflection;

namespace CrestCore.Domain;

/// The Public Suffix List (https://publicsuffix.org): the names under which
/// anyone may register a site, such as `com`, `co.uk` or `github.io`. A host's
/// registrable domain is the public suffix it ends in and one more label, so
/// `auth.example.co.uk` and `app.example.co.uk` share `example.co.uk` while
/// `alice.github.io` and `bob.github.io` share nothing. The list is read once,
/// from the copy built into the core, with every rule in its ASCII spelling,
/// as a page's origin spells a host.
internal static class PublicSuffixList {
    #region Types

    private sealed record Rules(HashSet<string> Names, HashSet<string> Wildcards, HashSet<string> Exceptions);

    #endregion

    #region Static Variables

    private const string ResourceName = "CrestCore.Domain.Sites.public_suffix_list.dat";

    private static readonly Lazy<Rules> Loaded = new(Load);

    #endregion

    #region Actions - Reading

    /// Whether `host` is itself a public suffix, such as `com` or `github.io`,
    /// or a single label with no rule, which no one registers either. An IP
    /// address is not.
    internal static bool IsPublicSuffix(string host) {
        ArgumentNullException.ThrowIfNull(host);
        string name = Normalized(host);
        if (name.Length == 0 || IsAddress(name)) return false;
        string[] labels = name.Split('.');
        return SuffixLength(labels) >= labels.Length;
    }

    /// The registrable domain of `host`: its public suffix and one label more,
    /// such as `example.co.uk` for `auth.example.co.uk`. An IP address, or a
    /// host that is itself a public suffix, is its own.
    internal static string RegistrableDomain(string host) {
        ArgumentNullException.ThrowIfNull(host);
        string name = Normalized(host);
        if (name.Length == 0 || IsAddress(name)) return name;
        string[] labels = name.Split('.');
        int suffix = SuffixLength(labels);
        return suffix >= labels.Length ? name : string.Join('.', labels[^(suffix + 1)..]);
    }

    /// Whether pages at `first` and `second` belong to the same registrable
    /// domain, as the steps of one sign-in do.
    internal static bool AreSameSite(string first, string second) =>
        RegistrableDomain(first) == RegistrableDomain(second);

    #endregion

    #region Actions - Matching

    /// How many trailing labels of `labels` are its public suffix, by the
    /// list's algorithm: the longest matching rule wins, an exception rule
    /// gives back one label, and a name no rule matches ends in a one-label
    /// suffix.
    private static int SuffixLength(string[] labels) {
        var rules = Loaded.Value;
        int longest = 1;
        for (int count = 1; count <= labels.Length; count++) {
            string candidate = string.Join('.', labels[^count..]);
            if (rules.Exceptions.Contains(candidate)) return count - 1;
            if (rules.Names.Contains(candidate)) longest = count;
            if (count < labels.Length && rules.Wildcards.Contains(candidate)) longest = count + 1;
        }
        return longest;
    }

    private static bool IsAddress(string name) =>
        name.Contains(':', StringComparison.Ordinal) || name.Split('.').All(label => label.Length > 0 && label.All(char.IsAsciiDigit));

    private static string Normalized(string host) =>
        host.Trim().TrimEnd('.').ToLower(CultureInfo.InvariantCulture);

    #endregion

    #region Actions - Loading

    private static Rules Load() {
        var names = new HashSet<string>(StringComparer.Ordinal);
        var wildcards = new HashSet<string>(StringComparer.Ordinal);
        var exceptions = new HashSet<string>(StringComparer.Ordinal);
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(ResourceName)
            ?? throw new InvalidOperationException("The public suffix list is missing from the core.");
        using var reader = new StreamReader(stream);
        var idn = new IdnMapping();
        while (reader.ReadLine() is { } line) {
            string rule = line.Trim();
            if (rule.Length == 0 || rule.StartsWith("//", StringComparison.Ordinal)) continue;
            var set = names;
            if (rule.StartsWith('!')) (set, rule) = (exceptions, rule[1..]);
            else if (rule.StartsWith("*.", StringComparison.Ordinal)) (set, rule) = (wildcards, rule[2..]);
            string ascii;
            try {
                ascii = idn.GetAscii(rule);
            } catch (ArgumentException) {
                continue;
            }
            set.Add(ascii.ToLower(CultureInfo.InvariantCulture));
        }
        return new(names, wildcards, exceptions);
    }

    #endregion
}
