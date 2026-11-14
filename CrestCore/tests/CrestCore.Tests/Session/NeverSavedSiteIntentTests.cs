using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

public sealed partial class BrowserContractsTests {
    /// A person adds, edits and removes the sites a Space never offers to
    /// save passwords on; a site that names no website is refused and changes
    /// nothing.
    [Fact]
    public void ASpacesNeverSavedSitesAreAddedEditedAndRemoved() {
        var fixture = SavedSession();
        using var device = new TestDevice(fixture.Document["session"]!);
        CredentialPreferences Preferences() =>
            device.Authority.Current.Spaces.Single(space => space.Id == fixture.Space).Settings.CredentialPreferences;

        device.Send(new NeverSaveSite(device.Workspace, fixture.Space, "https://foo.this.com/login", false, null));
        device.Send(new NeverSaveSite(device.Workspace, fixture.Space, "*.google.com", false, null));
        Assert.Equal([new NeverSavedSite("foo.this.com", false), new NeverSavedSite("google.com", true)],
            Preferences().NeverSavedSites);
        Assert.True(Preferences().NeverSaves("accounts.google.com"));
        Assert.False(Preferences().NeverSaves("bar.this.com"));

        device.Send(new NeverSaveSite(device.Workspace, fixture.Space, "foo.this.com", true, new NeverSavedSite("foo.this.com", false)));
        Assert.Equal([new NeverSavedSite("foo.this.com", true), new NeverSavedSite("google.com", true)], Preferences().NeverSavedSites);

        Assert.Equal(new InvalidNeverSavedSite(), Assert.Throws<Rejected>(() =>
            device.Send(new NeverSaveSite(device.Workspace, fixture.Space, "not a site", false, null))).Rejection);

        Assert.IsType<SubdomainsOfPublicSuffix>(Assert.Throws<Rejected>(() =>
            device.Send(new NeverSaveSite(device.Workspace, fixture.Space, "github.io", true, null))).Rejection);

        device.Send(new ForgetNeverSavedSite(device.Workspace, fixture.Space, new NeverSavedSite("google.com", true)));
        Assert.Equal([new NeverSavedSite("foo.this.com", true)], Preferences().NeverSavedSites);

        device.Send(new SetCredentialPreferences(device.Workspace, fixture.Space, Preferences() with { SavePromptSeconds = 1 }));
        Assert.Equal(CredentialPreferences.MinimumSavePromptSeconds, Preferences().SavePromptSeconds);
    }
}
