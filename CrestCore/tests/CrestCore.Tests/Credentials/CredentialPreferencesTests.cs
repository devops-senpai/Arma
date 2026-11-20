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
            SuggestsInPrivateWindows: true);
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));

        var stored = (JsonObject)Older.DeepClone();
        stored["savePromptSeconds"] = 900;
        Assert.Equal(CredentialPreferences.MaximumSavePromptSeconds,
            StoredSessionCodec.DecodeCredentialPreferences(stored).SavePromptSeconds);
        Assert.Equal(CredentialPreferences.MinimumSavePromptSeconds, (chosen with { SavePromptSeconds = 1 }).Kept().SavePromptSeconds);
    }

    [Fact]
    public void NeverSavedSitesAreStoredAndAnUnreadableOneIsLeftOut() {
        var chosen = new CredentialPreferences(true, true, false,
            [new NeverSavedSite("google.com", true), new NeverSavedSite("foo.this.com", false)], CredentialAuthentication.EachTime);
        Assert.Equal(chosen, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(chosen)));

        var stored = (JsonObject)Older.DeepClone();
        stored["neverSavedSites"] = new JsonArray(
            new JsonObject { ["host"] = "Example.com", ["includesSubdomains"] = false },
            new JsonObject { ["host"] = "not a site" },
            new JsonObject { ["host"] = "co.uk", ["includesSubdomains"] = true });
        Assert.Equal([new NeverSavedSite("example.com", false)], StoredSessionCodec.DecodeCredentialPreferences(stored).NeverSavedSites);
    }

    [Fact]
    public void HowOftenASpaceAsksToAuthenticateIsStoredAndFollowed() {
        Assert.True(CredentialAuthentication.EachTime.Asks(1));
        Assert.True(CredentialAuthentication.EachTime.Asks(null));
        Assert.False(CredentialAuthentication.Every15Minutes.Asks(14 * 60));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(15 * 60));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(null));
        Assert.True(CredentialAuthentication.Every15Minutes.Asks(-5));
        Assert.False(CredentialAuthentication.Never.Asks(null));
        Assert.True(CredentialAuthentication.Never.ConfirmsChoosing);

        // Ask Each Time is the default, so a Space that never chose stores nothing and asks as before.
        var older = StoredSessionCodec.DecodeCredentialPreferences(Older.DeepClone());
        Assert.Equal(CredentialAuthentication.EachTime, older.Authentication);
        var never = older with { Authentication = CredentialAuthentication.Never };
        var stored = StoredSessionCodec.Encode(never);
        Assert.Equal("never", stored["authentication"]!.GetValue<string>());
        Assert.Equal(never, StoredSessionCodec.DecodeCredentialPreferences(stored));
        stored["authentication"] = "sometimes";
        Assert.Equal(CredentialAuthentication.EachTime, StoredSessionCodec.DecodeCredentialPreferences(stored).Authentication);
    }
}
