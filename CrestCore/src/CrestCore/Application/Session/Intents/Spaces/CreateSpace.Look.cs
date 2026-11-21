namespace CrestCore.Contracts;

/// `Look`, and `DarkLook` for dark windows, dress a new Space in a look the
/// device chose for new Spaces in place of the template's, under the
/// template's crest.
public sealed partial record CreateSpace {
    #region Actions - Looks

    /// `space` in the chosen look, or as its template made it when none was chosen.
    private SpaceState Dressed(SpaceState space) {
        if (Look is not { } look) return space;
        // The Space keeps the crest its template gives it, in the look's colors.
        var made = space.Settings.Look;
        SpaceBranding Dressed(SpaceBranding chosen) => SpaceBranding.Normalized(chosen with {
            Crest = made.Crest,
            IconStyle = made.IconStyle,
            SymbolColor = made.SymbolColor
        });
        return space with {
            Settings = space.Settings with { Branding = Dressed(look), DarkBranding = DarkLook is { } dark ? Dressed(dark) : null }
        };
    }

    #endregion
}
