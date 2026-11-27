using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A generated password a person shapes draws only from the groups they chose,
/// never from nothing, and stays within what the site allows.
public sealed class PasswordGenerationTests {
    private static IReadOnlyList<string> Groups => StrongPasswordRecipe.CharacterGroups;

    [Fact]
    public void AGenerationDrawsFromTheGroupsItIncludes() {
        var letters = PasswordRequirements.None.Recipe(PasswordStyle.Grouped, new PasswordGeneration(24, true, true, false, false));
        Assert.Equal(24, letters.Length);
        Assert.Equal([Groups[0], Groups[1]], letters.Groups);
        Assert.Equal(letters.Groups, letters.Required);

        var nothing = PasswordRequirements.None.Recipe(PasswordStyle.Grouped, new PasswordGeneration(20, false, false, false, false));
        Assert.Equal([Groups[0]], nothing.Groups);
    }

    [Fact]
    public void TheSitesLimitsStillBoundTheChoice() {
        var shorter = new PasswordRequirements(null, 12, null).Recipe(PasswordStyle.Grouped,
            new PasswordGeneration(40, true, true, true, true));
        Assert.Equal(12, shorter.Length);
        // A length outside the choice's own bounds is held to them.
        Assert.Equal(PasswordGeneration.MinimumLength, PasswordRequirements.None.Recipe(PasswordStyle.Grouped,
            new PasswordGeneration(5, true, true, true, true)).Length);
        Assert.Equal(PasswordGeneration.MaximumLength, PasswordRequirements.None.Recipe(PasswordStyle.Grouped,
            new PasswordGeneration(500, true, true, true, true)).Length);

        var digitsOnly = new PasswordRequirements(null, null, "allowed: digit;").Recipe(PasswordStyle.Grouped,
            new PasswordGeneration(20, true, true, false, false));
        Assert.All(digitsOnly.Groups, group => Assert.True(group.All(char.IsAsciiDigit)));
    }

    [Fact]
    public void WithoutAChoiceTheSiteAndStyleDecideAsBefore() {
        var before = PasswordRequirements.None.Recipe(PasswordStyle.Grouped);
        var unchosen = PasswordRequirements.None.Recipe(PasswordStyle.Grouped, null);
        Assert.Equal((before.Length, before.Separator), (unchosen.Length, unchosen.Separator));
        Assert.Equal(before.Groups, unchosen.Groups);
    }
}
