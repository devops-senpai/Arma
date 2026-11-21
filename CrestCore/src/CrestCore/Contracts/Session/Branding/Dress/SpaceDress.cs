namespace CrestCore.Contracts;

#region Types

/// <summary>The one color a Space's sidebar text reads in, in place of the tone
/// <see cref="SpaceBranding.TextColorMode"/> gives it, and the one its quieter text
/// reads in, such as New Tab and Clear. Either left null follows the system.</summary>
public sealed record SidebarTextDress(BrandColor? Color, BrandColor? SecondaryColor);

/// <summary>The colors a Space's folders wear when they have none of their own:
/// <see cref="Color"/> on the front, <see cref="BackColor"/> on the back face and
/// <see cref="OutlineColor"/> around them. <see cref="HighlightColor"/> tints a folder's
/// rows while it is open, hovered or chosen, at <see cref="HighlightOpacity"/>; a null
/// opacity leaves the tint to <see cref="SpaceBranding.FolderColorIntensity"/>, as
/// before a look could choose one. <see cref="Overrides"/> are the colors single
/// folders wear instead, by path. Every color left null follows the Space.</summary>
public sealed record FolderDress(BrandColor? Color, BrandColor? BackColor, BrandColor? OutlineColor,
    BrandColor? HighlightColor, double? HighlightOpacity, FolderColorOverrides? Overrides);

/// <summary>The colors of the popovers a Space's window presents, such as Site
/// Controls: their fill, text, quieter text, accent at <see cref="AccentOpacity"/>, and
/// their plain buttons' fill and outline. Each color left null keeps the flyout
/// surface's own.</summary>
public sealed record PopoverDress(BrandColor? BackgroundColor, BrandColor? TextColor, BrandColor? SecondaryTextColor,
    BrandColor? AccentColor, double AccentOpacity, BrandColor? ButtonColor, BrandColor? ButtonOutlineColor);

/// <summary>The controls over a Space's sidebar, the address field and the pins:
/// <see cref="FillColor"/> at <see cref="FillOpacity"/>, and the colors their text and
/// quieter text read in. Each color left null keeps the window's own.</summary>
public sealed record ControlsDress(BrandColor? FillColor, double FillOpacity, BrandColor? TextColor,
    BrandColor? SecondaryTextColor);

#endregion

/// <summary>
/// What a Space's look sets beyond its banner and crest: the colors its sidebar
/// text, folders, command palette, popovers and controls wear. Each part left
/// null keeps the look Crest gives it, so a look without a dress draws as every
/// build always drew it. A dress travels inside <see cref="SpaceBranding"/>, so a
/// Space copies it in with the rest of a look it is given.
/// </summary>
public sealed record SpaceDress(SidebarTextDress? Text, FolderDress? Folders, SpacePaletteLook? CommandPalette,
    PopoverDress? Popovers, ControlsDress? Controls) {
    #region Variables

    /// Whether the dress sets nothing at all.
    public bool IsBare => Text is null && Folders is null && CommandPalette is null && Popovers is null && Controls is null;

    #endregion

    #region Actions - Normalization

    /// This dress with every color a color and every opacity within 0 through 1,
    /// each part that sets nothing left out, or null when nothing is left.
    public SpaceDress? Normalized() {
        var dress = new SpaceDress(Normalized(Text), Normalized(Folders), Normalized(CommandPalette), Normalized(Popovers),
            Normalized(Controls));
        return dress.IsBare ? null : dress;
    }

    private static SidebarTextDress? Normalized(SidebarTextDress? text) =>
        text is null || (text.Color is null && text.SecondaryColor is null) ? null
        : new(Normalized(text.Color), Normalized(text.SecondaryColor));

    private static FolderDress? Normalized(FolderDress? folders) {
        if (folders is null) return null;
        var normalized = new FolderDress(Normalized(folders.Color), Normalized(folders.BackColor), Normalized(folders.OutlineColor),
            Normalized(folders.HighlightColor), folders.HighlightOpacity is { } opacity ? Unit(opacity) : null,
            Normalized(folders.Overrides));
        return normalized == new FolderDress(null, null, null, null, null, null) ? null : normalized;
    }

    /// A palette look with each surface's tint a color and its opacity within 0
    /// through 1. A look that tints neither appearance is no look at all.
    private static SpacePaletteLook? Normalized(SpacePaletteLook? look) {
        if (look is null) return null;
        var normalized = new SpacePaletteLook(Normalized(look.Light), Normalized(look.Dark));
        return normalized.IsTinted ? normalized : null;
    }

    private static SpacePaletteSurface Normalized(SpacePaletteSurface surface) =>
        new(Normalized(surface.Tint), Unit(surface.Opacity), Normalized(surface.TextColor), Normalized(surface.SelectedTextColor));

    private static PopoverDress? Normalized(PopoverDress? popovers) =>
        popovers is null || (popovers.BackgroundColor ?? popovers.TextColor ?? popovers.SecondaryTextColor ?? popovers.AccentColor
            ?? popovers.ButtonColor ?? popovers.ButtonOutlineColor) is null ? null
        : new(Normalized(popovers.BackgroundColor), Normalized(popovers.TextColor), Normalized(popovers.SecondaryTextColor),
            Normalized(popovers.AccentColor), Unit(popovers.AccentOpacity, fallback: 1), Normalized(popovers.ButtonColor),
            Normalized(popovers.ButtonOutlineColor));

    private static ControlsDress? Normalized(ControlsDress? controls) =>
        controls is null || (controls.FillColor ?? controls.TextColor ?? controls.SecondaryTextColor) is null ? null
        : new(Normalized(controls.FillColor), Unit(controls.FillOpacity, fallback: 1), Normalized(controls.TextColor),
            Normalized(controls.SecondaryTextColor));

    /// Overrides with a path and at least one color, the last for each path,
    /// at most the most a look keeps; null when none remain.
    private static FolderColorOverrides? Normalized(FolderColorOverrides? overrides) {
        if (overrides is null) return null;
        var kept = new List<FolderColorOverride>();
        foreach (var entry in overrides.Overrides) {
            string path = entry.Path.Trim();
            if (path.Length is 0 or > FolderColorOverrides.MaximumPathLength) continue;
            if (entry.Color is null && entry.BackColor is null && entry.OutlineColor is null) continue;
            kept.RemoveAll(existing => existing.Path == path);
            kept.Add(new(path, Normalized(entry.Color), Normalized(entry.BackColor), Normalized(entry.OutlineColor)));
        }
        return kept.Count == 0 ? null : new([.. kept.Take(FolderColorOverrides.MaximumCount)]);
    }

    private static BrandColor? Normalized(BrandColor? color) =>
        color is null ? null : new(Unit(color.Red), Unit(color.Green), Unit(color.Blue), Unit(color.Alpha, fallback: 1));

    /// An opacity or color component, kept within 0 through 1. A value that is
    /// not a number falls back to `fallback`.
    private static double Unit(double value, double fallback = 0) => double.IsFinite(value) ? Math.Clamp(value, 0, 1) : fallback;

    #endregion
}
