namespace CrestCore.Contracts;

/// How a Space generates passwords: `Length` characters drawn from the groups
/// it includes, lowercase and uppercase letters, numbers and symbols. A
/// generation that includes no group draws from lowercase letters, so there is
/// always something to draw from.
public sealed record PasswordGeneration(int Length, bool Lowercase, bool Uppercase, bool Numbers, bool Symbols) {
    #region Static Variables

    public const int DefaultLength = 16;
    public const int MinimumLength = 8;
    public const int MaximumLength = 64;

    /// Sixteen characters from every group.
    internal static readonly PasswordGeneration Default = new(DefaultLength, true, true, true, true);

    #endregion

    #region Mutators

    /// This generation as a Space keeps it: its length within range, and at
    /// least one group.
    public PasswordGeneration Kept() {
        var kept = this with { Length = Math.Clamp(Length, MinimumLength, MaximumLength) };
        return kept.Lowercase || kept.Uppercase || kept.Numbers || kept.Symbols ? kept : kept with { Lowercase = true };
    }

    #endregion
}
