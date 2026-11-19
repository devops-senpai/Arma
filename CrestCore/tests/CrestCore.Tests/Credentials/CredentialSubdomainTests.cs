using CrestCore.Application;
using CrestCore.Contracts;
using CrestCore.Domain;

using Xunit;

namespace CrestCore.Tests;

/// A saved password that reaches its site's subdomains: the Public Suffix List
/// decides what a registrable domain is, so a password never reaches the
/// subdomains of a public suffix, where each belongs to someone else, and
/// never reaches up from a subdomain to the site above it.
public sealed class CredentialSubdomainTests {
    [Fact]
    public void ThePublicSuffixListNamesRegistrableDomains() {
        Assert.True(SiteDomain.IsListedPublicSuffix("github.io"));
        Assert.True(SiteDomain.IsListedPublicSuffix("co.uk"));
        Assert.False(SiteDomain.IsListedPublicSuffix("example.com"));
        Assert.Equal("example.co.uk", SiteDomain.RegistrableDomain("auth.example.co.uk"));
        Assert.Equal("alice.github.io", SiteDomain.RegistrableDomain("www.alice.github.io"));
        Assert.Equal("10.0.0.1", SiteDomain.RegistrableDomain("10.0.0.1"));
        Assert.False(SiteDomain.AreSameSite("alice.github.io", "bob.github.io"));
    }

    [Fact]
    public void ASavedPasswordReachesSubdomainsOnlyWhenItSaysSo() {
        CredentialOrigin auth = new("https", "auth.example.com", 443);
        CredentialOrigin[] saved = [new("https", "example.com", 443), new("https", "example.com", 443),
            new("https", "github.io", 443), new("https", "example.com", 8443)];
        var app = new CrestApp();
        Assert.Equal([false, true, false, false], app.Query(new CredentialsFillingPage(auth, saved, [1, 2, 3])).Fills);
        // A password saved on a subdomain never fills the site above it.
        Assert.Equal([false], app.Query(new CredentialsFillingPage(new("https", "example.com", 443), [auth], [0])).Fills);
        Assert.True(app.Query(new CredentialSubdomainReach(new("https", "example.com", 443))).IsAllowed);
        Assert.IsType<SubdomainsOfPublicSuffix>(
            Assert.Throws<Rejected>(() => app.Query(new CredentialSubdomainReach(new("https", "github.io", 443)))).Rejection);
    }
}
