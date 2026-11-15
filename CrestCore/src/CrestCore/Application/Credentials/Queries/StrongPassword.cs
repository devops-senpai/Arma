using CrestCore.Application;

namespace CrestCore.Contracts;

/// How to compose a generated password as `Generation` describes, or as a
/// Space does by default when it is null. The password itself never exists in
/// the core.
public sealed record StrongPassword(PasswordGeneration? Generation) : Query<StrongPasswordRecipe> {
    #region Actions - Answering

    internal override StrongPasswordRecipe Answer(CrestApp app) {
        return StrongPasswordRecipe.For(Generation);
    }

    #endregion
}
