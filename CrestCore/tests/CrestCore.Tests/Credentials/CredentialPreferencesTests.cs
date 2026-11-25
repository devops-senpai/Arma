using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// How a Space's password choices are stored: a Space an older release stored
/// reads with the defaults and is written back unchanged, and a choice is kept
/// within its rules.
public sealed class CredentialPreferencesTests {
    private static readonly JsonObject Older = new() {
        ["isEnabled"] = true,
        ["syncsCrestPasswordsWithICloud"] = false,
        ["alsoOffersSaveToSystemPasswords"] = true
    };

    [Fact]
    public void PreferencesAnOlderReleaseStoredTakeTheDefaultsAndWriteBackUnchanged() {
        var decoded = StoredSessionCodec.DecodeCredentialPreferences(Older.DeepClone());
        Assert.Equal(new CredentialPreferences(true, false, true, []), decoded);
        Assert.Equal(CredentialPreferences.DefaultSavePromptSeconds, decoded.SavePromptSeconds);
        Assert.True(JsonNode.DeepEquals(Older, StoredSessionCodec.Encode(decoded)));
    }

    [Fact]
    public void TheSavePromptTimeIsStoredAndKeptWithinItsRange() {
        var chosen = new CredentialPreferences(true, true, false, [], SavePromptSeconds: 25);
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));

        var stored = (JsonObject)Older.DeepClone();
        stored["savePromptSeconds"] = 900;
        Assert.Equal(CredentialPreferences.MaximumSavePromptSeconds,
            StoredSessionCodec.DecodeCredentialPreferences(stored).SavePromptSeconds);
        Assert.Equal(CredentialPreferences.MinimumSavePromptSeconds, (chosen with { SavePromptSeconds = 1 }).Kept().SavePromptSeconds);
    }
}
