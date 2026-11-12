using CrestCore.Application;
using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

public sealed class FolderOutlineColorTests {
    /// A Space's folder outline color, its folder overrides by path, its
    /// sidebar's secondary text color, its folder highlight and its popover
    /// colors survive the stored session, and a branding without them reads
    /// back without them.
    [Fact]
    public void FolderOutlineColorSurvivesTheStoredSession() {
        var outline = new BrandColor(0.05, 0.44, 0.58);
        var branding = SpaceBranding.Neutral with { FolderOutlineColor = outline };

        var stored = StoredSessionCodec.Encode(branding);
        Assert.Equal(outline, StoredSessionCodec.DecodeBranding(stored).FolderOutlineColor);

        var overrides = new FolderColorOverrides([
            new(".HomeLab.proxmox", new BrandColor(0.9, 0.95, 0.98), BackColor: null, OutlineColor: outline),
            new(".library", Color: null, new BrandColor(0.5, 0.8, 0.9), OutlineColor: null),
        ]);
        var overridden = SpaceBranding.Normalized(SpaceBranding.Neutral with { FolderOverrides = overrides });
        Assert.Equal(overrides, StoredSessionCodec.DecodeBranding(StoredSessionCodec.Encode(overridden)).FolderOverrides);

        var secondaryText = new BrandColor(0.82, 0.9, 0.93);
        var readable = SpaceBranding.Normalized(SpaceBranding.Neutral with { SidebarSecondaryTextColor = secondaryText });
        Assert.Equal(secondaryText,
            StoredSessionCodec.DecodeBranding(StoredSessionCodec.Encode(readable)).SidebarSecondaryTextColor);

        var highlight = new BrandColor(0.7, 0.6, 0.9);
        var lit = SpaceBranding.Normalized(SpaceBranding.Neutral with { FolderHighlightColor = highlight, FolderHighlightOpacity = 0.4 });
        var litBack = StoredSessionCodec.DecodeBranding(StoredSessionCodec.Encode(lit));
        Assert.Equal(highlight, litBack.FolderHighlightColor);
        Assert.Equal(0.4, litBack.FolderHighlightOpacity, precision: 6);

        var popoverBack = new BrandColor(0.12, 0.1, 0.2);
        var popoverText = new BrandColor(0.95, 0.9, 0.7);
        var popoverSecondary = new BrandColor(0.7, 0.7, 0.8);
        var popoverAccent = new BrandColor(0.9, 0.4, 0.3);
        var dressed = SpaceBranding.Normalized(SpaceBranding.Neutral with { PopoverBackgroundColor = popoverBack, PopoverTextColor = popoverText });
        dressed = SpaceBranding.Normalized(dressed with { PopoverSecondaryTextColor = popoverSecondary, PopoverAccentColor = popoverAccent });
        dressed = SpaceBranding.Normalized(dressed with { PopoverAccentOpacity = 0.8, PopoverButtonColor = popoverSecondary });
        dressed = SpaceBranding.Normalized(dressed with { PopoverButtonOutlineColor = popoverAccent });
        var dressedBack = StoredSessionCodec.DecodeBranding(StoredSessionCodec.Encode(dressed));
        Assert.Equal(popoverBack, dressedBack.PopoverBackgroundColor);
        Assert.Equal(popoverText, dressedBack.PopoverTextColor);
        Assert.Equal(popoverSecondary, dressedBack.PopoverSecondaryTextColor);
        Assert.Equal(popoverAccent, dressedBack.PopoverAccentColor);
        Assert.Equal(0.8, dressedBack.PopoverAccentOpacity, precision: 6);
        Assert.Equal(popoverSecondary, dressedBack.PopoverButtonColor);
        Assert.Equal(popoverAccent, dressedBack.PopoverButtonOutlineColor);

        var plain = StoredSessionCodec.Encode(SpaceBranding.Neutral);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).FolderOutlineColor);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).FolderOverrides);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).SidebarSecondaryTextColor);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).FolderHighlightColor);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).PopoverBackgroundColor);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).PopoverTextColor);
        Assert.Null(StoredSessionCodec.DecodeBranding(plain).PopoverAccentColor);
        Assert.Equal(1, StoredSessionCodec.DecodeBranding(plain).PopoverAccentOpacity);
        Assert.Equal(SpaceBranding.DefaultHighlightOpacity, StoredSessionCodec.DecodeBranding(plain).FolderHighlightOpacity);

        // A record from before highlights keeps the tint its intensity gave.
        var older = StoredSessionCodec.Encode(SpaceBranding.Neutral with { FolderColorIntensity = 0.5 });
        older.Remove(StoredSessionCodec.Key.FolderHighlightOpacity);
        Assert.Equal(0.56, StoredSessionCodec.DecodeBranding(older).FolderHighlightOpacity, precision: 6);
    }
}
