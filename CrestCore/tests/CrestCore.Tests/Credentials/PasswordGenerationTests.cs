using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A generated password a person shapes keeps the recipe's lengths and draws
/// only from the groups they chose, and never from nothing.
public sealed class PasswordGenerationTests {
    [Fact]
    public void AGenerationDrawsFromTheGroupsItIncludesWithinTheRecipesLengths() {
        var all = StrongPasswordRecipe.For(null);
        var letters = new PasswordGeneration(24, true, true, false, false);
        var recipe = StrongPasswordRecipe.For(letters.Length, letters);
        Assert.Equal(24, recipe.Length);
        Assert.Equal([all.Groups[0], all.Groups[1]], recipe.Groups);
        Assert.Equal([all.Groups[0]], StrongPasswordRecipe.For(null, new PasswordGeneration(20, false, false, false, false)).Groups);
        Assert.Equal(all.Groups, StrongPasswordRecipe.For(null, new PasswordGeneration(20, true, true, true, true)).Groups);
        Assert.Equal(new InvalidPasswordLength(16, 64),
            Assert.Throws<Rejected>(() => StrongPasswordRecipe.For(15, letters)).Rejection);
        Assert.Equal((20, 16, 64), (PasswordGeneration.DefaultLength, PasswordGeneration.MinimumLength, PasswordGeneration.MaximumLength));
    }
}
