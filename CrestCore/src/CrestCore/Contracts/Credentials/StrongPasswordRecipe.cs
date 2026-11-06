namespace CrestCore.Contracts;

/// How a strong password is composed: its length and the character groups it
/// draws from. The platform draws one character from every group, fills the
/// rest from all groups and shuffles, using its own secure random source, so
/// the password itself never exists in the core. The four groups a Space may
/// include meet common website requirements; characters that are easily
/// confused in proportional fonts are absent.
public sealed record StrongPasswordRecipe(int Length, IReadOnlyList<string> Groups) {
    #region Static Variables

    private static readonly string[] CharacterGroups = [
        "abcdefghijkmnopqrstuvwxyz",
        "ABCDEFGHJKLMNPQRSTUVWXYZ",
        "23456789",
        "-_.!@#$%^&*+="
    ];

    #endregion

    #region Actions - Generation

    /// The recipe `generation` describes, or sixteen characters from every
    /// group.
    internal static StrongPasswordRecipe For(PasswordGeneration? generation) {
        var resolved = generation ?? PasswordGeneration.Default;
        if (resolved.Length is < PasswordGeneration.MinimumLength or > PasswordGeneration.MaximumLength)
            throw new Rejected(new InvalidPasswordLength(PasswordGeneration.MinimumLength, PasswordGeneration.MaximumLength));
        resolved = resolved.Kept();
        bool[] included = [resolved.Lowercase, resolved.Uppercase, resolved.Numbers, resolved.Symbols];
        return new(resolved.Length, [.. CharacterGroups.Where((_, index) => included[index])]);
    }

    #endregion
}
