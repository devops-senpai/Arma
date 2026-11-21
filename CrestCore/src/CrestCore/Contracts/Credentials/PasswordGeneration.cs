namespace CrestCore.Contracts;

/// How one generated password is made, as a person chooses it: `Length`
/// characters drawn from the groups it includes, lowercase and uppercase
/// letters, numbers and symbols. A generation that includes no group draws
/// from lowercase letters, so there is always something to draw from. Its
/// lengths are the strong password recipe's own.
public sealed record PasswordGeneration(int Length, bool Lowercase, bool Uppercase, bool Numbers, bool Symbols) {
    #region Static Variables

    public const int DefaultLength = StrongPasswordRecipe.DefaultLength;
    public const int MinimumLength = StrongPasswordRecipe.MinimumLength;
    public const int MaximumLength = StrongPasswordRecipe.MaximumLength;

    #endregion

    #region Actions - Groups

    /// The groups of `groups`, given in the order lowercase, uppercase,
    /// numbers and symbols, that this generation includes, or the first when
    /// it includes none.
    internal IReadOnlyList<string> Including(IReadOnlyList<string> groups) {
        bool[] included = [Lowercase, Uppercase, Numbers, Symbols];
        string[] kept = [.. groups.Where((_, index) => included[index])];
        return kept.Length > 0 ? kept : [groups[0]];
    }

    #endregion
}
