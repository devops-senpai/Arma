using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;
using CrestCore.Domain;

using Xunit;

namespace CrestCore.Tests;

/// A Space's never-saved sites and its other password preferences: how a site
/// is read and matched, that a listed site is never offered a save while its
/// saved passwords still fill, that subdomains of a public suffix are never
/// included, how a saved password reaches subdomains, and how the preferences
/// are stored, including the sites a test build kept under another key.
public sealed class NeverSavedSiteTests {
    private static readonly CredentialOrigin Foo = new("https", "foo.this.com", 443);
    private static readonly CredentialOrigin Bar = new("https", "bar.this.com", 443);

    private static CredentialFormFacts Facts(CredentialCaptureEvent kind, CredentialOrigin origin) =>
        new(kind, origin, origin, IsMainFrame: true, HasFormId: true, HasUsername: true, HasPassword: true,
            CredentialPasswordKind.Current, HasVisiblePasswordField: null, HasFillTarget: true);

    private static NeverSavedSite Never(string host, bool subdomains) => new(host, subdomains);

    [Fact]
    public void ASiteIsReadFromWhatAPersonTypes() {
        Assert.Equal(Never("example.com", false), NeverSavedSite.Reading("https://Example.com/login?next=1", false));
        Assert.Equal(Never("example.com", false), NeverSavedSite.Reading("  example.com.  ", false));
        Assert.Equal(Never("example.com", true), NeverSavedSite.Reading("*.example.com", false));
        Assert.Equal(Never("example.com", true), NeverSavedSite.Reading("example.com", true));
        Assert.Null(NeverSavedSite.Reading("", false));
        Assert.Null(NeverSavedSite.Reading("*.", false));
        Assert.Null(NeverSavedSite.Reading("exa*mple.com", false));
        Assert.Null(NeverSavedSite.Reading("not a site", false));
    }

    [Fact]
    public void SubdomainsOfAPublicSuffixAreNeverIncluded() {
        Assert.Equal(new SubdomainsOfPublicSuffix("github.io"),
            Assert.Throws<Rejected>(() => NeverSavedSite.Reading("*.github.io", false)).Rejection);
        Assert.IsType<SubdomainsOfPublicSuffix>(Assert.Throws<Rejected>(() => NeverSavedSite.Reading("co.uk", true)).Rejection);
        Assert.Equal(Never("github.io", false), NeverSavedSite.Reading("github.io", false));
        Assert.Equal(Never("alice.github.io", true), NeverSavedSite.Reading("alice.github.io", true));

        Assert.True(PublicSuffixList.IsPublicSuffix("github.io"));
        Assert.False(PublicSuffixList.IsPublicSuffix("devopssenpai.com"));
        Assert.Equal("example.co.uk", PublicSuffixList.RegistrableDomain("auth.example.co.uk"));
        Assert.Equal("devopssenpai.com", PublicSuffixList.RegistrableDomain("authelia.devopssenpai.com"));
        Assert.Equal("alice.github.io", PublicSuffixList.RegistrableDomain("www.alice.github.io"));
        Assert.Equal("10.0.0.1", PublicSuffixList.RegistrableDomain("10.0.0.1"));
    }

    [Fact]
    public void ASiteCoversItsSubdomainsOnlyWhenItSaysSo() {
        var exact = Never("foo.this.com", false);
        Assert.True(exact.Covers("FOO.this.com"));
        Assert.False(exact.Covers("bar.this.com"));
        Assert.False(exact.Covers("a.foo.this.com"));
        var wide = Never("google.com", true);
        Assert.True(wide.Covers("google.com"));
        Assert.True(wide.Covers("accounts.google.com"));
        Assert.False(wide.Covers("notgoogle.com"));
    }

    [Fact]
    public void AListedSiteIsNeverOfferedASaveButStillFills() {
        IReadOnlyList<NeverSavedSite> sites = [Never("foo.this.com", false)];
        var submit = Facts(CredentialCaptureEvent.Submit, Foo);
        Assert.Equal(CredentialCaptureAction.Ignore, submit.Event.Decide(submit, null, null, 0, sites).Action);
        var sibling = Facts(CredentialCaptureEvent.Submit, Bar);
        Assert.Equal(CredentialCaptureAction.CaptureCandidate, sibling.Event.Decide(sibling, null, null, 0, sites).Action);
        var focus = Facts(CredentialCaptureEvent.Focus, Foo);
        Assert.Equal(CredentialCaptureAction.OfferFill, focus.Event.Decide(focus, null, null, 0, sites).Action);
    }

    [Fact]
    public void ASavedPasswordReachesSubdomainsOnlyWhenItSaysSo() {
        CredentialOrigin authelia = new("https", "authelia.devopssenpai.com", 443);
        CredentialOrigin[] saved = [new("https", "devopssenpai.com", 443), new("https", "devopssenpai.com", 443),
            new("https", "github.io", 443), new("https", "devopssenpai.com", 8443)];
        var area = new CrestApp();
        Assert.Equal([false, true, false, false], area.Query(new CredentialsFillingPage(authelia, saved, [1, 2, 3])).Fills);
        // A password saved on a subdomain never fills the site above it.
        Assert.Equal([false], area.Query(new CredentialsFillingPage(new("https", "devopssenpai.com", 443), [authelia], [0])).Fills);
    }

    [Fact]
    public void PreferencesAnOlderReleaseStoredTakeTheDefaults() {
        var older = new JsonObject { ["isEnabled"] = true, ["syncsCrestPasswordsWithICloud"] = false, ["alsoOffersSaveToSystemPasswords"] = true };
        var decoded = StoredSessionCodec.DecodeCredentialPreferences(older);
        Assert.Equal(new CredentialPreferences(true, false, true, CredentialPreferences.DefaultSavePromptSeconds, [],
            CredentialAuthentication.Never, SuggestsInPrivateWindows: false, PasswordGeneration.Default, AllowsCommandLine: false), decoded);
        Assert.True(JsonNode.DeepEquals(older, StoredSessionCodec.Encode(decoded)));
    }

    [Fact]
    public void PreferencesAreStoredAndReadBackWithTheirSitesAndGeneration() {
        var preferences = new CredentialPreferences(true, true, false, 12,
            [Never("google.com", true), Never("foo.this.com", false)], CredentialAuthentication.Every15Minutes,
            SuggestsInPrivateWindows: true, new PasswordGeneration(24, true, true, false, false), AllowsCommandLine: true);
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

        // Don't Ask is the default; a Space that asks keeps its choice.
        Assert.Equal(CredentialAuthentication.Never,
            StoredSessionCodec.DecodeCredentialPreferences(new JsonObject { ["isEnabled"] = true }).Authentication);
        var eachTime = StoredSessionCodec.DecodeCredentialPreferences(new JsonObject { ["isEnabled"] = true }) with {
            Authentication = CredentialAuthentication.EachTime
        };
        var stored = StoredSessionCodec.Encode(eachTime);
        Assert.Equal("eachTime", stored["authentication"]!.GetValue<string>());
        Assert.Equal(eachTime, StoredSessionCodec.DecodeCredentialPreferences(stored));
        var unknown = new JsonObject { ["isEnabled"] = true, ["authentication"] = "sometimes" };
        Assert.Equal(CredentialAuthentication.Never, StoredSessionCodec.DecodeCredentialPreferences(unknown).Authentication);
    }

    [Fact]
    public void StoredPreferencesAreKeptWithinTheirRules() {
        var stored = new JsonObject {
            ["isEnabled"] = true,
            ["savePromptSeconds"] = 900,
            ["generation"] = new JsonObject {
                ["length"] = 500,
                ["lowercase"] = false,
                ["uppercase"] = false,
                ["numbers"] = false,
                ["symbols"] = false
            },
            ["neverSavedSites"] = new JsonArray(
                new JsonObject { ["host"] = "Example.com", ["includesSubdomains"] = false },
                new JsonObject { ["host"] = "not a site" },
                new JsonObject { ["host"] = "github.io", ["includesSubdomains"] = true }),
            // What a test build kept: only its sites that never save are kept.
            ["passwordSites"] = new JsonArray(
                new JsonObject { ["host"] = "bank.example", ["includesSubdomains"] = true, ["neverSaves"] = true, ["category"] = "Money" },
                new JsonObject { ["host"] = "filed.example", ["neverSaves"] = false, ["category"] = "Home" })
        };
        var decoded = StoredSessionCodec.DecodeCredentialPreferences(stored);
        Assert.Equal(CredentialPreferences.MaximumSavePromptSeconds, decoded.SavePromptSeconds);
        Assert.Equal(new PasswordGeneration(PasswordGeneration.MaximumLength, true, false, false, false), decoded.Generation);
        Assert.Equal([Never("example.com", false), Never("bank.example", true)], decoded.NeverSavedSites);
        Assert.False(StoredSessionCodec.Encode(decoded).ContainsKey("passwordSites"));
    }
}
