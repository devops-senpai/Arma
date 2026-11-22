namespace CrestCore.Contracts;

/// <see cref="SpaceSettings.DarkBranding"/> is the look a Space wears instead while
/// windows are dark, or null to wear <see cref="SpaceSettings.Look"/> in both
/// appearances; <see cref="DarkLook"/> is what it wears in the dark.
public sealed partial record SpaceSettings {
    #region Variables

    /// <summary>The branding the Space wears while windows are dark: its dark look in
    /// today's units, or <see cref="Look"/> when it keeps one look for both.</summary>
    [Resolved]
    public SpaceBranding DarkLook => DarkBranding?.InTodaysUnits() ?? Look;

    #endregion
}
