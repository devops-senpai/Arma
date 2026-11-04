using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A Space's never-saved sites and how long its offer to save stays: how a
/// site is read and matched, that a listed site is never offered a save while
/// its saved passwords still fill, and how the preferences are stored.
public sealed class NeverSavedSiteTests {
    private static readonly CredentialOrigin Foo = new("https", "foo.this.com", 443);
    private static readonly CredentialOrigin Bar = new("https", "bar.this.com", 443);

    private static CredentialFormFacts Facts(CredentialCaptureEvent kind, CredentialOrigin origin) =>
        new(kind, origin, origin, IsMainFrame: true, HasFormId: true, HasUsername: true, HasPassword: true,
            CredentialPasswordKind.Current, HasVisiblePasswordField: null, HasFillTarget: true);

    [Fact]
    public void ASiteIsReadFromWhatAPersonTypes() {
        Assert.Equal(new NeverSavedSite("example.com", false), NeverSavedSite.Reading("https://Example.com/login?next=1", false));
        Assert.Equal(new NeverSavedSite("example.com", false), NeverSavedSite.Reading("  example.com.  ", false));
        Assert.Equal(new NeverSavedSite("example.com", true), NeverSavedSite.Reading("*.example.com", false));
        Assert.Equal(new NeverSavedSite("example.com", true), NeverSavedSite.Reading("example.com", true));
        Assert.Null(NeverSavedSite.Reading("", false));
        Assert.Null(NeverSavedSite.Reading("*.", false));
        Assert.Null(NeverSavedSite.Reading("exa*mple.com", false));
        Assert.Null(NeverSavedSite.Reading("not a site", false));
    }

    [Fact]
    public void ASiteCoversItsSubdomainsOnlyWhenItSaysSo() {
        var exact = new NeverSavedSite("foo.this.com", false);
        Assert.True(exact.Covers("FOO.this.com"));
        Assert.False(exact.Covers("bar.this.com"));
        Assert.False(exact.Covers("a.foo.this.com"));
        var wide = new NeverSavedSite("google.com", true);
        Assert.True(wide.Covers("google.com"));
        Assert.True(wide.Covers("accounts.google.com"));
        Assert.False(wide.Covers("notgoogle.com"));
    }

    [Fact]
    public void AListedSiteIsNeverOfferedASaveButStillFills() {
        IReadOnlyList<NeverSavedSite> sites = [new("foo.this.com", false)];
        var submit = Facts(CredentialCaptureEvent.Submit, Foo);
        Assert.Equal(CredentialCaptureAction.Ignore, submit.Event.Decide(submit, null, null, 0, sites).Action);
        var sibling = Facts(CredentialCaptureEvent.Submit, Bar);
        Assert.Equal(CredentialCaptureAction.CaptureCandidate, sibling.Event.Decide(sibling, null, null, 0, sites).Action);
        var focus = Facts(CredentialCaptureEvent.Focus, Foo);
        Assert.Equal(CredentialCaptureAction.OfferFill, focus.Event.Decide(focus, null, null, 0, sites).Action);
    }

    [Fact]
    public void PreferencesAnOlderReleaseStoredTakeTheDefaults() {
        var older = new JsonObject { ["isEnabled"] = true, ["syncsCrestPasswordsWithICloud"] = false, ["alsoOffersSaveToSystemPasswords"] = true };
        var decoded = StoredSessionCodec.DecodeCredentialPreferences(older);
        Assert.Equal(new CredentialPreferences(true, false, true, CredentialPreferences.DefaultSavePromptSeconds, [],
            CredentialAuthentication.EachTime), decoded);
        Assert.True(JsonNode.DeepEquals(older, StoredSessionCodec.Encode(decoded)));
    }

    [Fact]
    public void PreferencesAreStoredAndReadBackWithTheirSites() {
        var preferences = new CredentialPreferences(true, true, false, 12,
            [new("google.com", true), new("foo.this.com", false)], CredentialAuthentication.Every15Minutes);
        Assert.Equal(preferences, StoredSessionCodec.DecodeCredentialPreferences(StoredSessionCodec.Encode(preferences)));
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

        var never = StoredSessionCodec.DecodeCredentialPreferences(new JsonObject { ["isEnabled"] = true }) with {
            Authentication = CredentialAuthentication.Never
        };
        var stored = StoredSessionCodec.Encode(never);
        Assert.Equal("never", stored["authentication"]!.GetValue<string>());
        Assert.Equal(never, StoredSessionCodec.DecodeCredentialPreferences(stored));
        var unknown = new JsonObject { ["isEnabled"] = true, ["authentication"] = "sometimes" };
        Assert.Equal(CredentialAuthentication.EachTime, StoredSessionCodec.DecodeCredentialPreferences(unknown).Authentication);
    }

    [Fact]
    public void StoredPreferencesAreKeptWithinTheirRules() {
        var stored = new JsonObject {
            ["isEnabled"] = true,
            ["savePromptSeconds"] = 900,
            ["neverSavedSites"] = new JsonArray(
                new JsonObject { ["host"] = "Example.com", ["includesSubdomains"] = false },
                new JsonObject { ["host"] = "not a site" },
                new JsonObject { ["host"] = "example.com", ["includesSubdomains"] = true })
        };
        var decoded = StoredSessionCodec.DecodeCredentialPreferences(stored);
        Assert.Equal(CredentialPreferences.MaximumSavePromptSeconds, decoded.SavePromptSeconds);
        Assert.Equal([new NeverSavedSite("example.com", true)], decoded.NeverSavedSites);
    }
}
