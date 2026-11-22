using System.Text.Json.Nodes;

using CrestCore.Contracts;

namespace CrestCore.Application;

internal static partial class StoredSessionCodec {
    #region Actions - Credential choices

    /// `value`, a Space's credential preferences as an older release wrote
    /// them, with each choice since written only once it differs from its
    /// default, so a Space that kept them is stored exactly as before.
    private static JsonObject WithCredentialChoices(JsonObject value, CredentialPreferences preferences) {
        if (preferences.SavePromptSeconds != DefaultCredentialPreferences.SavePromptSeconds)
            value[Key.SavePromptSeconds] = preferences.SavePromptSeconds;
        return value;
    }

    #endregion
}
