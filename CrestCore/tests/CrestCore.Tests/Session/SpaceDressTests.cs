using System.Text.Json.Nodes;

using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A look's dress and a Space's dark look survive the stored session, a dress
/// an older build wrote as keys of the branding reads into the nested dress,
/// and a Space made with a look the device chose wears it.
public sealed partial class BrowserContractsTests {
    #region Static Variables

    private static readonly BrandColor DressMauve = new(0.776, 0.627, 0.965);
    private static readonly BrandColor DressSky = new(0.016, 0.647, 0.898);
    private static readonly BrandColor DressInk = new(0.298, 0.31, 0.412);

    #endregion

    #region Actions - Tests

    [Fact]
    public void ADressSurvivesTheStoredSessionAndALookWithoutOneWritesNone() {
        var dress = new SpaceDress(new(DressInk, SecondaryColor: null),
            new(DressSky, BackColor: null, DressMauve, HighlightColor: DressSky, HighlightOpacity: 0.4,
                new FolderColorOverrides([new(".Home.lab", DressMauve, BackColor: null, OutlineColor: null)])),
            new(new(DressMauve, 0.6, DressInk), SpacePaletteSurface.Neutral),
            new(DressInk, DressMauve, SecondaryTextColor: null, DressSky, AccentOpacity: 0.8, ButtonColor: null, ButtonOutlineColor: DressMauve),
            new(DressSky, FillOpacity: 0.7, DressInk, SecondaryTextColor: null));
        var look = SpaceBranding.Normalized(SpaceBranding.Neutral with { Dress = dress });

        Assert.Equal(dress, look.Dress);
        Assert.Equal(look, StoredSessionCodec.DecodeBranding(StoredSessionCodec.Encode(look)));

        var plain = StoredSessionCodec.Encode(SpaceBranding.Neutral);
        Assert.Null(plain[StoredSessionCodec.DressKey.Dress]);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).Dress);
        // A dress that sets nothing is no dress at all.
        Assert.Null(SpaceBranding.Normalized(SpaceBranding.Neutral with { Dress = new(null, null, null, null, null) }).Dress);
    }

    /// Builds before the nested dress wrote each part as a key of the branding,
    /// and a folder highlight opacity only where it differed from what the
    /// folder color intensity gave; such a record reads as that dress, its
    /// highlight still left to the intensity, and writes the nested dress alone.
    [Fact]
    public void ADressAnOlderBuildWroteAsBrandingKeysReadsIntoTheNestedDress() {
        var stored = StoredSessionCodec.Encode(SpaceBranding.Neutral with { FolderColorIntensity = 0.5 });
        stored["folderColor"] = StoredSessionCodec.Encode(DressSky);
        stored["folderOutlineColor"] = StoredSessionCodec.Encode(DressMauve);
        stored["folderOverrides"] = new JsonArray(new JsonObject { ["path"] = ".Home", ["color"] = StoredSessionCodec.Encode(DressInk) });
        stored["sidebarTextColor"] = StoredSessionCodec.Encode(DressInk);
        stored["commandPalette"] = new JsonObject {
            ["light"] = new JsonObject { ["tint"] = StoredSessionCodec.Encode(DressMauve), ["opacity"] = 0.6 }
        };
        stored["popoverAccentColor"] = StoredSessionCodec.Encode(DressMauve);
        stored["controlsFillColor"] = StoredSessionCodec.Encode(DressSky);
        stored["controlsFillOpacity"] = 0.5;

        var look = StoredSessionCodec.DecodeBranding(stored);
        var dress = Assert.IsType<SpaceDress>(look.Dress);

        Assert.Equal(new SidebarTextDress(DressInk, SecondaryColor: null), dress.Text);
        Assert.Equal(DressSky, dress.Folders!.Color);
        Assert.Equal(DressMauve, dress.Folders.OutlineColor);
        Assert.Null(dress.Folders.HighlightOpacity);
        Assert.Equal(0.5, look.FolderColorIntensity);
        Assert.Equal(".Home", Assert.Single(dress.Folders.Overrides!.Overrides).Path);
        Assert.Equal(new SpacePaletteSurface(DressMauve, 0.6, TextColor: null), dress.CommandPalette!.Light);
        Assert.Equal(DressMauve, dress.Popovers!.AccentColor);
        Assert.Equal(1, dress.Popovers.AccentOpacity);
        Assert.Equal(new ControlsDress(DressSky, 0.5, TextColor: null, SecondaryTextColor: null), dress.Controls);

        var written = StoredSessionCodec.Encode(look);
        Assert.NotNull(written[StoredSessionCodec.DressKey.Dress]);
        Assert.All(StoredSessionCodec.DressKey.Flat.All, key => Assert.False(written.ContainsKey(key), key));
        Assert.Equal(look, StoredSessionCodec.DecodeBranding(written));
    }

    /// Each theme Arma ships with is a look every device draws as it is, and
    /// one that pairs a dark look carries it.
    [Fact]
    public void ABundledThemeIsAlreadyWithinTheRangesEveryDeviceDraws() {
        foreach (var scheme in SpaceScheme.All.Where(scheme => scheme.Look.Dress is not null)) {
            Assert.Equal(scheme.Look, SpaceBranding.Normalized(scheme.Look));
            if (scheme.DarkLook is { } dark) Assert.Equal(dark, SpaceBranding.Normalized(dark));
        }
        Assert.NotNull(SpaceScheme.Latte.Look.Dress);
        Assert.NotNull(SpaceScheme.LatteMocha.DarkLook?.Dress);
        Assert.Null(SpaceScheme.Neutral.Look.Dress);
    }

    /// A Space made with the look the device chose for new Spaces wears it and
    /// its dark look, dress and all, through the stored session; one made
    /// without wears its template's.
    [Fact]
    public void ASpaceMadeWithTheDevicesDefaultThemeWearsIt() {
        var session = SavedSession().Document["session"]!;
        using var device = new TestDevice(session);
        var window = device.Showing(session);
        var themed = Guid.NewGuid();
        var plain = Guid.NewGuid();
        var scheme = SpaceScheme.LatteMocha;

        device.Send(new CreateSpace(device.Workspace, window, themed, scheme.Look, scheme.DarkLook));
        device.Send(new CreateSpace(device.Workspace, window, plain));

        var settings = device.Authority.Current.Space(themed)!.Settings;
        var crest = device.Authority.Current.Space(plain)!.Settings.Look.Crest;
        Assert.Equal(scheme.Look.Dress, settings.Look.Dress);
        Assert.Equal(scheme.Look.Colors, settings.Look.Colors);
        Assert.Equal(scheme.DarkLook!.Dress, settings.DarkLook.Dress);
        Assert.Equal(scheme.DarkLook.Colors, settings.DarkLook.Colors);
        // It keeps the crest its template gives a new Space.
        Assert.Equal(crest.Backplate, settings.Look.Crest.Backplate);
        Assert.Equal(settings.Look.Crest, settings.DarkLook.Crest);
        var restored = StoredSessionCodec.DecodeSession(StoredSessionCodec.Encode(device.Authority.Current)).Space(themed)!.Settings;
        Assert.Equal(settings.Branding, restored.Branding);
        Assert.Equal(settings.DarkBranding, restored.DarkBranding);

        var untouched = device.Authority.Current.Space(plain)!.Settings;
        Assert.Null(untouched.DarkBranding);
        Assert.Null(untouched.Look.Dress);
        Assert.Equal(untouched.Look, untouched.DarkLook);
    }

    #endregion
}
