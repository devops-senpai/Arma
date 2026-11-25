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
        Assert.Equal(new CredentialPreferences(true, false, true, [], CredentialAuthentication.EachTime), decoded);
        Assert.Equal(CredentialPreferences.DefaultSavePromptSeconds, decoded.SavePromptSeconds);
        Assert.True(JsonNode.DeepEquals(Older, StoredSessionCodec.Encode(decoded)));
    }

    [Fact]
    public void TheSavePromptTimeIsStoredAndKeptWithinItsRange() {
        var chosen = new CredentialPreferences(true, true, false, [], CredentialAuthentication.EachTime, SavePromptSeconds: 25,
            AllowsCommandLine: true);
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));

        var stored = (JsonObject)Older.DeepClone();
        stored["savePromptSeconds"] = 900;
        Assert.Equal(CredentialPreferences.MaximumSavePromptSeconds,
            StoredSessionCodec.DecodeCredentialPreferences(stored).SavePromptSeconds);
        Assert.Equal(CredentialPreferences.MinimumSavePromptSeconds, (chosen with { SavePromptSeconds = 1 }).Kept().SavePromptSeconds);
    }

    [Fact]
    public void TheAuthenticationChoiceIsStoredOnlyWhenChosenAndDecidesWhenToAsk() {
        Assert.False(StoredSessionCodec.Encode(StoredSessionCodec.DecodeCredentialPreferences(Older.DeepClone()))
            .ContainsKey("authentication"));
        var chosen = new CredentialPreferences(true, true, false, [], CredentialAuthentication.Every15Minutes);
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));

        Assert.True(CredentialAuthentication.EachTime.Asks(1));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(null));
        Assert.False(CredentialAuthentication.Every15Minutes.Asks(60));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(15 * 60));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(-1));
        Assert.False(CredentialAuthentication.Never.Asks(null));
    }

    [Fact]
    public void SuggestingInPrivateWindowsIsStoredOnlyWhenChosen() {
        var chosen = new CredentialPreferences(true, true, false, [], CredentialAuthentication.EachTime,
            SuggestsInPrivateWindows: true);
        Assert.Equal(true, StoredSessionCodec.Encode(chosen)["suggestsInPrivateWindows"]?.GetValue<bool>());
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));
        Assert.False(StoredSessionCodec.Encode(chosen with { SuggestsInPrivateWindows = false })
            .ContainsKey("suggestsInPrivateWindows"));
    }
}
