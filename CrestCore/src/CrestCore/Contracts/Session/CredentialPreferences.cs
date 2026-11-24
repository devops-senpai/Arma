namespace CrestCore.Contracts;

/// <summary>
/// Whether a Space offers to save and fill passwords, and where it keeps them.
/// The offer to save closes after <see cref="SavePromptSeconds"/>. Older
/// releases stored only the first three, and a Space that stored none of the
/// rest takes their defaults.
/// </summary>
public sealed record CredentialPreferences(
    bool IsEnabled,
    bool SyncsCrestPasswordsWithICloud,
    bool AlsoOffersSaveToSystemPasswords,
    int SavePromptSeconds = CredentialPreferences.DefaultSavePromptSeconds) {
    #region Static Variables

    /// How long the offer to save stays unless a person chooses otherwise.
    public const int DefaultSavePromptSeconds = 10;
    /// The shortest and longest a person may keep the offer up.
    public const int MinimumSavePromptSeconds = 3;
    public const int MaximumSavePromptSeconds = 60;

    #endregion

    #region Mutators

    /// These preferences as a Space keeps them: the offer's time within its
    /// range.
    public CredentialPreferences Kept() => this with {
        SavePromptSeconds = Math.Clamp(SavePromptSeconds, MinimumSavePromptSeconds, MaximumSavePromptSeconds)
    };

    #endregion
}
