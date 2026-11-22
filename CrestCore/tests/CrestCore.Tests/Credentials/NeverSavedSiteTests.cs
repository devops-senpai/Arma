using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// The websites a Space never offers to save passwords on: how a site is read
/// from what a person types and matched against a page, that subdomains of a
/// public suffix are never included, and that a listed site is never offered
/// a save while its saved passwords still fill.
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
        Assert.Equal(new SubdomainsOfPublicSuffix("co.uk"),
            Assert.Throws<Rejected>(() => NeverSavedSite.Reading("*.co.uk", false)).Rejection);
        Assert.IsType<SubdomainsOfPublicSuffix>(Assert.Throws<Rejected>(() => NeverSavedSite.Reading("com", true)).Rejection);
        Assert.Equal(Never("co.uk", false), NeverSavedSite.Reading("co.uk", false));
        Assert.Equal(Never("example.co.uk", true), NeverSavedSite.Reading("example.co.uk", true));
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
        var app = new CrestApp();
        IReadOnlyList<NeverSavedSite> sites = [Never("foo.this.com", false)];
        CredentialCaptureAction Action(CredentialCaptureEvent kind, CredentialOrigin origin) =>
            app.Query(new CredentialCapture(Facts(kind, origin), null, null, 0, sites)).Action;
        Assert.Equal(CredentialCaptureAction.Ignore, Action(CredentialCaptureEvent.Submit, Foo));
        Assert.Equal(CredentialCaptureAction.CaptureCandidate, Action(CredentialCaptureEvent.Submit, Bar));
        Assert.Equal(CredentialCaptureAction.OfferFill, Action(CredentialCaptureEvent.Focus, Foo));
    }
}
