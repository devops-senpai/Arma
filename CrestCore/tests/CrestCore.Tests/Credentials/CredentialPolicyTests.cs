using CrestCore.Contracts;
using CrestCore.Domain;

using Xunit;

namespace CrestCore.Tests;

public sealed class CredentialPolicyTests {
    private static readonly CredentialOrigin Login = new("https", "accounts.example.com", 443);
    private static readonly CredentialOrigin Embedded = new("https", "embedded.example.com", 443);
    private static readonly CredentialOrigin Plain = new("http", "accounts.example.com", 80);

    private static CredentialFormFacts Facts(CredentialCaptureEvent kind, CredentialOrigin? frame = null,
        CredentialOrigin? top = null, bool mainFrame = true, bool username = false, bool password = false,
        CredentialPasswordKind? passwordKind = CredentialPasswordKind.Current, bool? visible = null, bool target = true) =>
        new(kind, frame ?? Login, top ?? Login, mainFrame, true, username, password, passwordKind, visible, target);

    private static CredentialCaptureDecision Decide(CredentialFormFacts facts, CredentialUsernameHint? hint,
        CredentialPendingCandidate? pending, double now) =>
        facts.Event.Decide(facts, hint, pending, now);

    private static Rejection Refusal(Func<object?> rule) => Assert.Throws<Rejected>(rule).Rejection;

    [Fact]
    public void CaptureRequiresSecureFrameAndTopLevelOrigins() {
        Assert.True(Login.IsSecureUnder(Login));
        Assert.False(Plain.IsSecureUnder(Login));
        Assert.False(Login.IsSecureUnder(Plain));
        Assert.Equal(CredentialCaptureAction.Ignore,
            Decide(Facts(CredentialCaptureEvent.Username, top: Plain, username: true), null, null, 0).Action);
        Assert.Equal(CredentialCaptureAction.Ignore,
            Decide(Facts(CredentialCaptureEvent.Submit, frame: Plain, username: true, password: true), null, null, 0).Action);
        Assert.Equal(CredentialSaveValidity.InsecureOrigin, new CredentialPendingCandidate(Plain, 0).SaveValidity(Login, 1));
    }

    [Fact]
    public void AUsernameHintAppliesToTheSameSiteWithinItsLifetime() {
        var hint = new CredentialUsernameHint(Login, Login, 1_000);
        Assert.True(hint.Applies(Login, Login, 1_001));
        Assert.True(hint.Applies(Login, Login, 1_000 + CredentialUsernameHint.Lifetime));
        // A sign-in that asks for the password on another host of the same site.
        Assert.True(hint.Applies(Embedded, Embedded, 1_001));
        Assert.False(hint.Applies(Login, Login, 1_001 + CredentialUsernameHint.Lifetime));
        CredentialOrigin elsewhere = new("https", "example.org", 443), insecure = new("http", "accounts.example.com", 80);
        Assert.False(hint.Applies(elsewhere, elsewhere, 1_001));
        Assert.False(hint.Applies(insecure, Login, 1_001));
        // Hosts under a public suffix belong to different people.
        CredentialOrigin alice = new("https", "alice.github.io", 443), bob = new("https", "bob.github.io", 443);
        Assert.False(new CredentialUsernameHint(alice, alice, 1_000).Applies(bob, bob, 1_001));
    }

    [Fact]
    public void TheSaveMatchIsTheMostRecentRecordForTheSameAccountIgnoringCase() {
        var older = new CredentialRecord(Guid.NewGuid(), "Person@Example.com", 1_000, null);
        var newer = new CredentialRecord(Guid.NewGuid(), "person@example.com", 2_000, null);
        var other = new CredentialRecord(Guid.NewGuid(), "someone", 3_000, null);
        Assert.Equal(newer, CredentialRecord.Matching("PERSON@example.com", [older, newer, other]));
        Assert.Null(CredentialRecord.Matching("nobody", [older, newer, other]));
        // Canonically equivalent spellings of one account match.
        var composed = new CredentialRecord(Guid.NewGuid(), "José", 1, null);
        Assert.Equal(composed, CredentialRecord.Matching("josé", [composed]));
        Assert.Null(CredentialRecord.Matching("person", [new(Guid.NewGuid(), "", 9, null)]));
        Assert.Equal(new InvalidCredentialRecord(), Refusal(() => CredentialRecord.Matching("person", [new(Guid.NewGuid(), null, 1, null)])));
        Assert.Equal(new InvalidCredentialUsername(), Refusal(() => CredentialRecord.Matching("", [composed])));
    }

    [Fact]
    public void AnUnchangedPasswordIsAlreadyStoredAndAMissingSecretCreatesARecord() {
        var id = Guid.NewGuid();
        Assert.Equal(new CredentialSavePlan(CredentialSavePlanKind.Create, null), CredentialSavePlan.For(null, null));
        Assert.Equal(new CredentialSavePlan(CredentialSavePlanKind.Create, null), CredentialSavePlan.For(id, null));
        var unchanged = CredentialSavePlan.For(id, new(id, PasswordMatches: true));
        Assert.Equal(new CredentialSavePlan(CredentialSavePlanKind.AlreadyStored, id), unchanged);
        Assert.False(unchanged.RequiresConfirmation);
        var changed = CredentialSavePlan.For(id, new(id, PasswordMatches: false));
        Assert.Equal(new CredentialSavePlan(CredentialSavePlanKind.Update, id), changed);
        Assert.True(changed.RequiresConfirmation);
        Assert.Equal(new StaleCredentialComparison(), Refusal(() => CredentialSavePlan.For(id, new(Guid.NewGuid(), true))));
        Assert.Equal(new StaleCredentialComparison(), Refusal(() => CredentialSavePlan.For(null, new(id, true))));
    }

    [Fact]
    public void GeneratedPasswordsUseTheChosenUnambiguousGroupsWithinTheSupportedLengths() {
        var recipe = StrongPasswordRecipe.For(null);
        Assert.Equal(PasswordGeneration.DefaultLength, recipe.Length);
        Assert.Equal(4, recipe.Groups.Count);
        Assert.All(recipe.Groups, group => Assert.True(group.All(char.IsAscii) && !group.Any(char.IsWhiteSpace)));
        Assert.DoesNotContain(recipe.Groups, group => group.IndexOfAny(['l', 'I', 'O', '0', '1']) >= 0);
        Assert.Equal(64, StrongPasswordRecipe.For(PasswordGeneration.Default with { Length = 64 }).Length);
        var lettersOnly = StrongPasswordRecipe.For(PasswordGeneration.Default with { Numbers = false, Symbols = false });
        Assert.Equal([recipe.Groups[0], recipe.Groups[1]], lettersOnly.Groups);
        // A generation that includes nothing still draws from lowercase letters.
        Assert.Equal([recipe.Groups[0]], StrongPasswordRecipe.For(new PasswordGeneration(12, false, false, false, false)).Groups);
        Assert.Equal(new InvalidPasswordLength(8, 64), Refusal(() => StrongPasswordRecipe.For(PasswordGeneration.Default with { Length = 7 })));
        Assert.IsType<InvalidPasswordLength>(Refusal(() => StrongPasswordRecipe.For(PasswordGeneration.Default with { Length = 65 })));
    }

    [Fact]
    public void PasskeyAccessChecksTheCapabilityThenTheDeviceThenConsent() {
        Assert.Equal(PasskeyAccessStatus.ManagedCapabilityRequired,
            new PasskeyAccess(false, PasskeyDeviceConfiguration.NotConfigured, PasskeyAuthorizationState.Authorized).Status);
        Assert.Equal(PasskeyAccessStatus.DeviceNotConfigured,
            new PasskeyAccess(true, PasskeyDeviceConfiguration.NotConfigured, PasskeyAuthorizationState.Authorized).Status);
        Assert.Equal(PasskeyAccessStatus.Authorized,
            new PasskeyAccess(true, PasskeyDeviceConfiguration.Unknown, PasskeyAuthorizationState.Authorized).Status);
        Assert.Equal(PasskeyAccessStatus.Denied,
            new PasskeyAccess(true, PasskeyDeviceConfiguration.Configured, PasskeyAuthorizationState.Denied).Status);
        Assert.Equal(PasskeyAccessStatus.NotDetermined,
            new PasskeyAccess(true, PasskeyDeviceConfiguration.Configured, PasskeyAuthorizationState.NotDetermined).Status);
    }

    [Fact]
    public void SystemPasswordWriteThroughIsOfferedOnlyForAnOptedInOrdinarySpace() {
        Assert.True(new SystemPasswordOffer(true, SystemPasswordWriteThroughAvailability.Available, false).Offers);
        Assert.False(new SystemPasswordOffer(false, SystemPasswordWriteThroughAvailability.Available, false).Offers);
        Assert.False(new SystemPasswordOffer(true, SystemPasswordWriteThroughAvailability.Available, true).Offers);
        Assert.False(new SystemPasswordOffer(true, SystemPasswordWriteThroughAvailability.IsolatedLaunch, false).Offers);
    }
}
