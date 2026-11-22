using System.Text.Json.Nodes;

using CrestCore.Contracts;

namespace CrestCore.Application;

internal static partial class StoredSessionCodec {
    #region Actions - Credential choices

    /// `value`, a Space's credential preferences as an older release wrote
    /// them, with each choice since written only once it differs from its
    /// default, so a Space that kept them is stored exactly as before.
    private static JsonObject WithCredentialChoices(JsonObject value, CredentialPreferences preferences) {
        if (preferences.NeverSavedSites.Count > 0)
            value[Key.NeverSavedSites] = new JsonArray([.. preferences.NeverSavedSites.Select(site => (JsonNode)new JsonObject {
                [Key.Host] = site.Host,
                [Key.IncludesSubdomains] = site.IncludesSubdomains
            })]);
        if (preferences.Authentication != DefaultCredentialPreferences.Authentication)
            value[Key.Authentication] = preferences.Authentication.Name;
        if (preferences.SavePromptSeconds != DefaultCredentialPreferences.SavePromptSeconds)
            value[Key.SavePromptSeconds] = preferences.SavePromptSeconds;
        if (preferences.SuggestsInPrivateWindows != DefaultCredentialPreferences.SuggestsInPrivateWindows)
            value[Key.SuggestsInPrivateWindows] = preferences.SuggestsInPrivateWindows;
        return value;
    }

    /// A Space's stored never-saved sites, leaving out one that no longer
    /// reads as one.
    private static IReadOnlyList<NeverSavedSite> DecodeNeverSavedSites(JsonObject value) =>
        [.. Items(value[Key.NeverSavedSites]).OfType<JsonObject>().Select(DecodeNeverSavedSite).OfType<NeverSavedSite>()];

    /// A stored never-saved site, or nil when it no longer reads as one,
    /// including one that would reach the subdomains of a public suffix.
    private static NeverSavedSite? DecodeNeverSavedSite(JsonObject value) {
        if (TolerantText(value[Key.Host]) is not { } host) return null;
        try {
            return NeverSavedSite.Reading(host, TolerantFlag(value[Key.IncludesSubdomains]) ?? false);
        } catch (Rejected) {
            return null;
        }
    }

    #endregion
}
