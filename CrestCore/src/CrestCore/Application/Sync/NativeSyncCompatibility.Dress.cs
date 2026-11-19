using CrestCore.Contracts;

namespace CrestCore.Application;

/// A look's dress, and the keys of the branding builds before it wrote its
/// parts as, which a newer branding replaces. They are read when the
/// branding's shape is made, so they come from properties rather than fields
/// that another part of the class might not have set yet.
internal static partial class NativeSyncCompatibility {
    #region Variables

    /// The branding's keys for its dress: the nested one and the flat ones.
    private static string DressKeys => "dress " + string.Join(' ', StoredSessionCodec.DressKey.Flat.All);

    private static Shape FolderOverride => new("path color backColor outlineColor",
        new() { ["color"] = Color, ["backColor"] = Color, ["outlineColor"] = Color });

    private static Shape PaletteSurface => new("tint opacity textColor", new() { ["tint"] = Color, ["textColor"] = Color });

    private static Shape PaletteLook => new("light dark", new() { ["light"] = PaletteSurface, ["dark"] = PaletteSurface });

    private static Shape Dress => new("text folders commandPalette popovers controls", new() {
        ["text"] = new("color secondaryColor", new() { ["color"] = Color, ["secondaryColor"] = Color }),
        ["folders"] = new("color backColor outlineColor highlightColor highlightOpacity overrides", new() {
            ["color"] = Color,
            ["backColor"] = Color,
            ["outlineColor"] = Color,
            ["highlightColor"] = Color,
            ["overrides"] = List(FolderOverride)
        }),
        ["commandPalette"] = PaletteLook,
        ["popovers"] = new("backgroundColor textColor secondaryTextColor accentColor accentOpacity buttonColor buttonOutlineColor", new() {
            ["backgroundColor"] = Color,
            ["textColor"] = Color,
            ["secondaryTextColor"] = Color,
            ["accentColor"] = Color,
            ["buttonColor"] = Color,
            ["buttonOutlineColor"] = Color
        }),
        ["controls"] = new("fillColor fillOpacity textColor secondaryTextColor",
            new() { ["fillColor"] = Color, ["textColor"] = Color, ["secondaryTextColor"] = Color })
    });

    #endregion
}
