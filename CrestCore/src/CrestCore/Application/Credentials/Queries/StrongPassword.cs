using CrestCore.Application;

namespace CrestCore.Contracts;

/// How to compose a generated password in `Style` that meets `Requirements`,
/// the limits of the field it is for, or, when the person chose one, as
/// `Generation` says within those limits. The password itself never exists in
/// the core.
public sealed record StrongPassword(PasswordRequirements Requirements, PasswordStyle Style, PasswordGeneration? Generation = null)
    : Query<StrongPasswordRecipe> {
    #region Actions - Answering

    internal override StrongPasswordRecipe Answer(CrestApp app) {
        ArgumentNullException.ThrowIfNull(Requirements);
        ArgumentNullException.ThrowIfNull(Style);
        return Requirements.Recipe(Style, Generation);
    }

    #endregion
}
