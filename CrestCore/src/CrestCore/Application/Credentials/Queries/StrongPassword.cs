using CrestCore.Application;

namespace CrestCore.Contracts;

/// How to compose a generated password of `Length` characters, or of the
/// default length when it is null. The password itself never exists in the core.
/// It draws from the groups `Generation` includes, or all of them.
public sealed record StrongPassword(int? Length, PasswordGeneration? Generation = null) : Query<StrongPasswordRecipe> {
    #region Actions - Answering

    internal override StrongPasswordRecipe Answer(CrestApp app) {
        return StrongPasswordRecipe.For(Length, Generation);
    }

    #endregion
}
