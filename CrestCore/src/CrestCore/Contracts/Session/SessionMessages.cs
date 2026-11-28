namespace CrestCore.Contracts;

#region Queries

/// Whether an intent would be accepted: `Refusal` names the rule that would
/// refuse it, or is null when the core would accept it.
public sealed record SendPermission(Rejection? Refusal);

#endregion

#region Rejections

/// A name is longer than `Limit` characters, or blank where one is required.
public sealed record InvalidName(int Limit) : Rejection;

/// The workspace already holds an open tab with this identity.
public sealed record TabAlreadyExists(Guid TabId) : Rejection;

/// The Space already holds `Limit` tabs, so it takes no more.
public sealed record TabLimitReached(int Limit) : Rejection;

/// The Space holds no tab with this identity.
public sealed record UnknownTab(Guid TabId) : Rejection;

/// `Url` names nothing a page can load: not an address a tab may show, nor
/// words to search for.
public sealed record UnsupportedAddress(string Url) : Rejection;

/// Another change to the workspace is being saved. The intent changed nothing
/// and may be sent again.
public sealed record WorkspaceBusy(Guid WorkspaceId) : Rejection;

#endregion

#region Models - Spaces

/// <summary>Whether a Space opens freely or asks the device owner to authenticate first.</summary>
public enum SpaceAccessPolicy { Open, DeviceOwnerAuthentication }

#endregion

#region Models - Tabs

/// <summary>A tab in its Space's archive, when it arrived there and why.</summary>
public sealed record ArchivedTabState(TabState Tab, DateTimeOffset ArchivedAt, ArchiveReason Reason);

/// <summary>A native view a tab shows instead of a web page. <see cref="Kind"/> stays
/// open so a view another build added survives here; <see cref="ResourceId"/> names a
/// separately stored document the view shows.</summary>
public sealed record NativeTabContent(string Kind, Guid? ResourceId = null);

/// <summary>The color a tab's icon sits on, taken from its page. Components run 0 through 1.</summary>
public sealed record TabIconAccent(double Red, double Green, double Blue);

#endregion

#region Models - Preferences

/// <summary>Whether a Space offers to save and fill passwords, where it keeps them, and
/// the sites the person asked it never to offer to save for. Only whether it offers
/// them reaches the person's other devices. <see cref="Authentication"/> is how often
/// showing or copying a saved password asks to authenticate. The offer to save closes
/// after <see cref="SavePromptSeconds"/>. <see cref="SuggestsInPrivateWindows"/> lets a
/// private window suggest, never save, the Space's passwords. Older records leave these
/// out and take the defaults.</summary>
public sealed record CredentialPreferences(bool IsEnabled, bool SyncsCrestPasswordsWithICloud, bool AlsoOffersSaveToSystemPasswords,
    IReadOnlyList<CredentialOrigin> NeverSavedSites, CredentialAuthentication Authentication,
    int SavePromptSeconds = CredentialPreferences.DefaultSavePromptSeconds, bool SuggestsInPrivateWindows = false) {
    #region Static Variables

    /// The most sites a Space keeps in its never-save list.
    public const int MaximumNeverSavedSites = 1000;

    /// How long the offer to save stays up unless a person chooses, and the
    /// range they choose from.
    public const int DefaultSavePromptSeconds = 10;
    public const int MinimumSavePromptSeconds = 3;
    public const int MaximumSavePromptSeconds = 60;

    #endregion

    #region Variables

    /// Collections are owned when constructed or replaced on a copy.
    public IReadOnlyList<CredentialOrigin> NeverSavedSites {
        get;
        init => field = [.. value];
    } = [.. NeverSavedSites];

    #endregion

    #region Actions - Reading

    /// Whether the person asked the Space never to offer to save for `site`.
    internal bool NeverSaves(CredentialOrigin site) => NeverSavedSites.Contains(site);

    /// These preferences with each number held to its range.
    internal CredentialPreferences Kept() => this with {
        SavePromptSeconds = Math.Clamp(SavePromptSeconds, MinimumSavePromptSeconds, MaximumSavePromptSeconds)
    };

    #endregion

    #region Actions - Equality

    public bool Equals(CredentialPreferences? other) => other is not null
        && IsEnabled == other.IsEnabled
        && SyncsCrestPasswordsWithICloud == other.SyncsCrestPasswordsWithICloud
        && AlsoOffersSaveToSystemPasswords == other.AlsoOffersSaveToSystemPasswords
        && NeverSavedSites.SequenceEqual(other.NeverSavedSites)
        && Authentication == other.Authentication
        && SavePromptSeconds == other.SavePromptSeconds
        && SuggestsInPrivateWindows == other.SuggestsInPrivateWindows;

    public override int GetHashCode() =>
        HashCode.Combine(IsEnabled, SyncsCrestPasswordsWithICloud, AlsoOffersSaveToSystemPasswords, NeverSavedSites.Count,
            Authentication.Name, SavePromptSeconds, SuggestsInPrivateWindows);

    #endregion
}

/// <summary>How long a Space keeps its history, archived tabs and downloads.</summary>
public sealed record DataRetentionPreferences(DataRetention History, DataRetention Archive, DataRetention Downloads);

/// <summary>A source language's chosen destination. Disabling keeps the destination.</summary>
public sealed record TranslationRule(string SourceLanguage, string TargetId, bool IsEnabled);

#endregion

#region Models - Colors

/// <summary>A color a person chose for a Space, folder or split. Components run 0 through 1.</summary>
public sealed record BrandColor(double Red, double Green, double Blue, double Alpha = 1);

#endregion
