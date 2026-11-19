using System.Text.Json.Nodes;

using CrestCore.Contracts;

namespace CrestCore.Application;

/// A look's dress and a Space's dark look, as the stored session and sync keep
/// them. A dress is one nested object beside the branding's own keys, written
/// only when the look has one, so a branding without one reads as every build
/// wrote it. Builds before the nested object wrote each part as a key of the
/// branding itself; those keys are read for as long as a journal from such a
/// build can replay.
internal static partial class StoredSessionCodec {
    #region Types

    internal static class DressKey {
        public const string DarkBranding = "darkBranding";
        public const string Dress = "dress";
        public const string Text = "text";
        public const string Folders = "folders";
        public const string CommandPalette = "commandPalette";
        public const string Popovers = "popovers";
        public const string Controls = "controls";
        public const string Color = "color";
        public const string SecondaryColor = "secondaryColor";
        public const string BackColor = "backColor";
        public const string OutlineColor = "outlineColor";
        public const string HighlightColor = "highlightColor";
        public const string HighlightOpacity = "highlightOpacity";
        public const string Overrides = "overrides";
        public const string Path = "path";
        public const string Light = "light";
        public const string Dark = "dark";
        public const string Tint = "tint";
        public const string Opacity = "opacity";
        public const string TextColor = "textColor";
        public const string BackgroundColor = "backgroundColor";
        public const string SecondaryTextColor = "secondaryTextColor";
        public const string AccentColor = "accentColor";
        public const string AccentOpacity = "accentOpacity";
        public const string ButtonColor = "buttonColor";
        public const string ButtonOutlineColor = "buttonOutlineColor";
        public const string FillColor = "fillColor";
        public const string FillOpacity = "fillOpacity";

        /// The keys builds before the nested dress wrote into the branding itself.
        public static class Flat {
            public const string FolderColor = "folderColor";
            public const string FolderBackColor = "folderBackColor";
            public const string FolderOutlineColor = "folderOutlineColor";
            public const string FolderOverrides = "folderOverrides";
            public const string FolderHighlightColor = "folderHighlightColor";
            public const string FolderHighlightOpacity = "folderHighlightOpacity";
            public const string CommandPalette = "commandPalette";
            public const string SidebarTextColor = "sidebarTextColor";
            public const string SidebarSecondaryTextColor = "sidebarSecondaryTextColor";
            public const string PopoverBackgroundColor = "popoverBackgroundColor";
            public const string PopoverTextColor = "popoverTextColor";
            public const string PopoverSecondaryTextColor = "popoverSecondaryTextColor";
            public const string PopoverAccentColor = "popoverAccentColor";
            public const string PopoverAccentOpacity = "popoverAccentOpacity";
            public const string PopoverButtonColor = "popoverButtonColor";
            public const string PopoverButtonOutlineColor = "popoverButtonOutlineColor";
            public const string ControlsFillColor = "controlsFillColor";
            public const string ControlsFillOpacity = "controlsFillOpacity";
            public const string ControlsTextColor = "controlsTextColor";
            public const string ControlsSecondaryTextColor = "controlsSecondaryTextColor";

            /// Every flat key, as the sync compatibility shape lists them.
            public static IReadOnlyList<string> All { get; } = [
                FolderColor, FolderBackColor, FolderOutlineColor, FolderOverrides, FolderHighlightColor, FolderHighlightOpacity,
                CommandPalette, SidebarTextColor, SidebarSecondaryTextColor, PopoverBackgroundColor, PopoverTextColor,
                PopoverSecondaryTextColor, PopoverAccentColor, PopoverAccentOpacity, PopoverButtonColor, PopoverButtonOutlineColor,
                ControlsFillColor, ControlsFillOpacity, ControlsTextColor, ControlsSecondaryTextColor
            ];
        }
    }

    #endregion

    #region Actions - Dress

    /// The dress a stored branding holds: its nested dress, or the flat keys a
    /// build before it wrote, or null when it holds neither.
    internal static SpaceDress? DecodeDress(JsonObject branding) {
        var dress = branding[DressKey.Dress] is JsonObject nested ? DecodeNestedDress(nested) : DecodeFlatDress(branding);
        return dress?.Normalized();
    }

    /// The dress a branding writes, beside its own keys.
    internal static JsonObject Encode(SpaceDress dress) {
        var value = new JsonObject();
        if (dress.Text is { } text) {
            var section = new JsonObject();
            Put(section, DressKey.Color, text.Color);
            Put(section, DressKey.SecondaryColor, text.SecondaryColor);
            value[DressKey.Text] = section;
        }
        if (dress.Folders is { } folders) {
            var section = new JsonObject();
            Put(section, DressKey.Color, folders.Color);
            Put(section, DressKey.BackColor, folders.BackColor);
            Put(section, DressKey.OutlineColor, folders.OutlineColor);
            Put(section, DressKey.HighlightColor, folders.HighlightColor);
            if (folders.HighlightOpacity is { } opacity) section[DressKey.HighlightOpacity] = opacity;
            if (folders.Overrides is { } overrides) section[DressKey.Overrides] = Encode(overrides);
            value[DressKey.Folders] = section;
        }
        if (dress.CommandPalette is { } palette) value[DressKey.CommandPalette] = Encode(palette);
        if (dress.Popovers is { } popovers) {
            var section = new JsonObject { [DressKey.AccentOpacity] = popovers.AccentOpacity };
            Put(section, DressKey.BackgroundColor, popovers.BackgroundColor);
            Put(section, DressKey.TextColor, popovers.TextColor);
            Put(section, DressKey.SecondaryTextColor, popovers.SecondaryTextColor);
            Put(section, DressKey.AccentColor, popovers.AccentColor);
            Put(section, DressKey.ButtonColor, popovers.ButtonColor);
            Put(section, DressKey.ButtonOutlineColor, popovers.ButtonOutlineColor);
            value[DressKey.Popovers] = section;
        }
        if (dress.Controls is { } controls) {
            var section = new JsonObject { [DressKey.FillOpacity] = controls.FillOpacity };
            Put(section, DressKey.FillColor, controls.FillColor);
            Put(section, DressKey.TextColor, controls.TextColor);
            Put(section, DressKey.SecondaryTextColor, controls.SecondaryTextColor);
            value[DressKey.Controls] = section;
        }
        return value;
    }

    private static SpaceDress DecodeNestedDress(JsonObject value) {
        var text = value[DressKey.Text] as JsonObject;
        var folders = value[DressKey.Folders] as JsonObject;
        var popovers = value[DressKey.Popovers] as JsonObject;
        var controls = value[DressKey.Controls] as JsonObject;
        return new(
            text is null ? null : new(OptionalColor(text[DressKey.Color]), OptionalColor(text[DressKey.SecondaryColor])),
            folders is null ? null
            : new(OptionalColor(folders[DressKey.Color]), OptionalColor(folders[DressKey.BackColor]),
                OptionalColor(folders[DressKey.OutlineColor]), OptionalColor(folders[DressKey.HighlightColor]),
                OptionalNumber(folders[DressKey.HighlightOpacity]), DecodeFolderOverrides(folders[DressKey.Overrides])),
            value[DressKey.CommandPalette] is JsonObject palette ? DecodePaletteLook(palette) : null,
            popovers is null ? null
            : new(OptionalColor(popovers[DressKey.BackgroundColor]), OptionalColor(popovers[DressKey.TextColor]),
                OptionalColor(popovers[DressKey.SecondaryTextColor]), OptionalColor(popovers[DressKey.AccentColor]),
                OptionalNumber(popovers[DressKey.AccentOpacity]) ?? 1, OptionalColor(popovers[DressKey.ButtonColor]),
                OptionalColor(popovers[DressKey.ButtonOutlineColor])),
            controls is null ? null
            : new(OptionalColor(controls[DressKey.FillColor]), OptionalNumber(controls[DressKey.FillOpacity]) ?? 1,
                OptionalColor(controls[DressKey.TextColor]), OptionalColor(controls[DressKey.SecondaryTextColor])));
    }

    /// The dress a build before the nested object wrote as keys of the branding.
    /// Its folder highlight opacity was written only where it differed from what
    /// the folder color intensity gave, so one left out still follows it.
    private static SpaceDress? DecodeFlatDress(JsonObject value) {
        if (!DressKey.Flat.All.Any(value.ContainsKey)) return null;
        return new(
            new(OptionalColor(value[DressKey.Flat.SidebarTextColor]), OptionalColor(value[DressKey.Flat.SidebarSecondaryTextColor])),
            new(OptionalColor(value[DressKey.Flat.FolderColor]), OptionalColor(value[DressKey.Flat.FolderBackColor]),
                OptionalColor(value[DressKey.Flat.FolderOutlineColor]), OptionalColor(value[DressKey.Flat.FolderHighlightColor]),
                OptionalNumber(value[DressKey.Flat.FolderHighlightOpacity]), DecodeFolderOverrides(value[DressKey.Flat.FolderOverrides])),
            value[DressKey.Flat.CommandPalette] is JsonObject palette ? DecodePaletteLook(palette) : null,
            new(OptionalColor(value[DressKey.Flat.PopoverBackgroundColor]), OptionalColor(value[DressKey.Flat.PopoverTextColor]),
                OptionalColor(value[DressKey.Flat.PopoverSecondaryTextColor]), OptionalColor(value[DressKey.Flat.PopoverAccentColor]),
                OptionalNumber(value[DressKey.Flat.PopoverAccentOpacity]) ?? 1, OptionalColor(value[DressKey.Flat.PopoverButtonColor]),
                OptionalColor(value[DressKey.Flat.PopoverButtonOutlineColor])),
            new(OptionalColor(value[DressKey.Flat.ControlsFillColor]), OptionalNumber(value[DressKey.Flat.ControlsFillOpacity]) ?? 1,
                OptionalColor(value[DressKey.Flat.ControlsTextColor]), OptionalColor(value[DressKey.Flat.ControlsSecondaryTextColor])));
    }

    /// A look's folder overrides, each an object with a path and its colors;
    /// an entry without a path is left out, and none leaves null.
    private static FolderColorOverrides? DecodeFolderOverrides(JsonNode? node) {
        if (node is not JsonArray entries) return null;
        var overrides = entries.OfType<JsonObject>()
            .Select(entry => (Path: Text(entry[DressKey.Path]), Entry: entry))
            .Where(pair => pair.Path is { Length: > 0 })
            .Select(pair => new FolderColorOverride(pair.Path!, OptionalColor(pair.Entry[DressKey.Color]),
                OptionalColor(pair.Entry[DressKey.BackColor]), OptionalColor(pair.Entry[DressKey.OutlineColor])))
            .ToArray();
        return overrides.Length == 0 ? null : new(overrides);
    }

    private static JsonArray Encode(FolderColorOverrides overrides) => [.. overrides.Overrides.Select(entry => {
        var value = new JsonObject { [DressKey.Path] = entry.Path };
        Put(value, DressKey.Color, entry.Color);
        Put(value, DressKey.BackColor, entry.BackColor);
        Put(value, DressKey.OutlineColor, entry.OutlineColor);
        return (JsonNode)value;
    })];

    /// The command palette's look over a Space. A surface that is missing or
    /// not an object is the system material alone.
    private static SpacePaletteLook DecodePaletteLook(JsonObject value) =>
        new(DecodePaletteSurface(value[DressKey.Light] as JsonObject), DecodePaletteSurface(value[DressKey.Dark] as JsonObject));

    private static SpacePaletteSurface DecodePaletteSurface(JsonObject? value) => value is null
        ? SpacePaletteSurface.Neutral
        : new(OptionalColor(value[DressKey.Tint]), OptionalNumber(value[DressKey.Opacity]) ?? 0,
            OptionalColor(value[DressKey.TextColor]));

    private static JsonObject Encode(SpacePaletteLook look) =>
        new() { [DressKey.Light] = Encode(look.Light), [DressKey.Dark] = Encode(look.Dark) };

    private static JsonObject Encode(SpacePaletteSurface surface) {
        var value = new JsonObject { [DressKey.Opacity] = surface.Opacity };
        Put(value, DressKey.Tint, surface.Tint);
        Put(value, DressKey.TextColor, surface.TextColor);
        return value;
    }

    /// A color a dress holds, or null where it holds none that is a color record.
    private static BrandColor? OptionalColor(JsonNode? node) => node is JsonObject color ? DecodeColor(color) : null;

    private static void Put(JsonObject value, string key, BrandColor? color) {
        if (color is not null) value[key] = Encode(color);
    }

    #endregion
}
