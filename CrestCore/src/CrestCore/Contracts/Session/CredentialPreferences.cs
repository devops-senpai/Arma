namespace CrestCore.Contracts;

/// <summary>
/// Whether a Space offers to save and fill passwords, where it keeps them,
/// and how often it asks to authenticate before showing or copying one
/// (<see cref="Authentication"/>).
/// The offer to save closes after <see cref="SavePromptSeconds"/>, and is never
/// made on the websites in <see cref="NeverSavedSites"/>, where saved
/// passwords still fill. Older releases stored only the first three, and a
/// Space that stored none of the rest takes their defaults.
/// </summary>
public sealed record CredentialPreferences(
    bool IsEnabled,
    bool SyncsCrestPasswordsWithICloud,
    bool AlsoOffersSaveToSystemPasswords,
    int SavePromptSeconds,
    IReadOnlyList<NeverSavedSite> NeverSavedSites,
    CredentialAuthentication Authentication) {
    #region Static Variables

    /// How long the offer to save stays unless a person chooses otherwise.
    public const int DefaultSavePromptSeconds = 6;
    /// The shortest and longest a person may keep the offer up.
    public const int MinimumSavePromptSeconds = 3;
    public const int MaximumSavePromptSeconds = 60;

    #endregion

    #region Variables

    /// Collections are owned when constructed or replaced on a copy.
    public IReadOnlyList<NeverSavedSite> NeverSavedSites {
        get;
        init => field = [.. value];
    } = [.. NeverSavedSites];

    #endregion

    #region Actions - Saving

    /// Whether the Space never offers to save a password on a page at `host`.
    public bool NeverSaves(string host) => NeverSavedSites.Any(site => site.Covers(host));

    #endregion

    #region Mutators

    /// These preferences as a Space keeps them: the prompt's time within its
    /// range, and one entry per host, the latest kept.
    public CredentialPreferences Kept() => this with {
        SavePromptSeconds = Math.Clamp(SavePromptSeconds, MinimumSavePromptSeconds, MaximumSavePromptSeconds),
        NeverSavedSites = NeverSavedSites.Where((site, index) =>
            !NeverSavedSites.Skip(index + 1).Any(later => later.NamesSameHost(site))).ToList()
    };

    /// These preferences never saving on `site`, in place of `replacing`
    /// when given, and of any entry for the same host.
    public CredentialPreferences NeverSaving(NeverSavedSite site, NeverSavedSite? replacing = null) {
        ArgumentNullException.ThrowIfNull(site);
        var kept = NeverSavedSites.Where(existing => existing != replacing && !existing.NamesSameHost(site)).ToList();
        var index = replacing is null ? -1 : NeverSavedSites.ToList().IndexOf(replacing);
        if (index >= 0 && index <= kept.Count) kept.Insert(index, site); else kept.Add(site);
        return (this with { NeverSavedSites = kept }).Kept();
    }

    /// These preferences offering to save on `site` again.
    public CredentialPreferences Forgetting(NeverSavedSite site) =>
        this with { NeverSavedSites = NeverSavedSites.Where(existing => existing != site).ToList() };

    #endregion

    #region Actions - Equality

    public bool Equals(CredentialPreferences? other) => other is not null
        && IsEnabled == other.IsEnabled
        && SyncsCrestPasswordsWithICloud == other.SyncsCrestPasswordsWithICloud
        && AlsoOffersSaveToSystemPasswords == other.AlsoOffersSaveToSystemPasswords
        && SavePromptSeconds == other.SavePromptSeconds
        && NeverSavedSites.SequenceEqual(other.NeverSavedSites)
        && Authentication == other.Authentication;

    public override int GetHashCode() => HashCode.Combine(IsEnabled, SyncsCrestPasswordsWithICloud, AlsoOffersSaveToSystemPasswords,
        SavePromptSeconds, NeverSavedSites.Count, Authentication);

    #endregion
}
