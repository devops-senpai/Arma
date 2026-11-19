namespace CrestCore.Contracts;

/// A look a Space can start from: the house's two wells, a Background the
/// plain sidebar wears and an Accent, each one color or a gradient, a Pattern
/// color a sidebar pattern draws in, and the house's arms. The arms follow the
/// Space's colors: they stand on a field of the Pattern, with the figure,
/// border and band in the Accent and the edge in the Background, so they
/// change with the Space's wells. Choosing one copies its look into the Space,
/// so a Space keeps the look it was given when a house changes.
public sealed class SpaceHouse {
    #region Static Variables

    /// The Space's color the sidebar wears.
    private const int Background = 0;

    /// The Space's color its icon, selected tabs and controls wear.
    private const int Accent = 1;

    /// The Space's color a sidebar pattern draws in.
    private const int Pattern = 2;

    /// Where a well's gradient runs unless a house turns it: top to bottom,
    /// as a color well starts one.
    private const double DownAngle = 90;

    /// An icy direwolf on steel, over slate.
    public static readonly SpaceHouse Winter = new("winter", "Winter", "CrestWinter", HouseLook(
        background: [Tincture.WinterSlate], accent: [Tincture.WinterIce], Tincture.WinterSteel,
        Arms(CrestBackplate.FrenchShield, CrestSymbol.Direwolf, CrestTrim.Line, edgeWidth: 0.35)));

    /// A lion in burnished gold on crimson, its double border and its sheen in
    /// gold, over red running down into oxblood.
    public static readonly SpaceHouse Lion = new("lion", "Lion", "CrestLion", HouseLook(
        background: [Tincture.LionGules, Tincture.LionOxblood], accent: [Tincture.LionOr, Tincture.LionGold],
        Tincture.LionCrimson,
        Arms(CrestBackplate.Shield, CrestSymbol.Lion, CrestTrim.DoubleLine, edgeWidth: 0.25, chargeScale: 1.25, trimWeight: 0.85,
            finish: CrestFinish.Sheen, depth: CrestDepth.Lifted),
        accentAngle: 45));

    /// A brass stag on slate blue, over midnight running down into a stormy
    /// sea.
    public static readonly SpaceHouse Storm = new("storm", "Storm", "CrestStorm", HouseLook(
        background: [Tincture.StormMidnight, Tincture.StormGunmetal], accent: [Tincture.StormBrass], Tincture.StormSlate,
        Arms(CrestBackplate.Hexagon, CrestSymbol.Stag, CrestTrim.DoubleLine, edgeWidth: 0.3), texture: 0.35));

    /// A flame-gold dragon on cinder, over a fire that burns up from the foot
    /// of the sidebar through blood red into char.
    public static readonly SpaceHouse Dragon = new("dragon", "Dragon", "CrestDragon", HouseLook(
        background: [Tincture.DragonChar, Tincture.DragonBlood, Tincture.DragonFire], accent: [Tincture.DragonFlame],
        Tincture.DragonCinder,
        Arms(CrestBackplate.Shield, CrestSymbol.Dragon, CrestTrim.Line, edgeWidth: 0.25, chargeScale: 1.25, depth: CrestDepth.Lifted),
        texture: 0.4));

    /// A rose-gold rose on fern in a wreath of laurel, over forest running
    /// down into a sunlit green.
    public static readonly SpaceHouse Meadow = new("meadow", "Meadow", "CrestMeadow", HouseLook(
        background: [Tincture.MeadowForest, Tincture.MeadowMoss], accent: [Tincture.MeadowRose], Tincture.MeadowVert,
        Arms(CrestBackplate.Circle, CrestSymbol.Rose, CrestTrim.Laurel, edgeWidth: 0.25), texture: 0.2));

    /// A kraken in gold weathering to patina on pewter, riveted round, over
    /// iron black running down into the deep.
    public static readonly SpaceHouse Iron = new("iron", "Iron", "CrestIron", HouseLook(
        background: [Tincture.IronBlack, Tincture.IronTide], accent: [Tincture.IronOr, Tincture.IronPatina],
        Tincture.IronPewter,
        Arms(CrestBackplate.Octagon, CrestSymbol.Kraken, CrestTrim.Beaded, edgeWidth: 0.5, finish: CrestFinish.Embossed),
        accentAngle: 45, texture: 0.5));

    /// A silver trout leaping over waves of azure and blue, over a bright blue
    /// running down into teal.
    public static readonly SpaceHouse River = new("river", "River", "CrestRiver", HouseLook(
        background: [Tincture.RiverNavy, Tincture.RiverLapis], accent: [Tincture.RiverArgent], Tincture.RiverAzure,
        Arms(CrestBackplate.Banner, CrestSymbol.Fish, CrestTrim.Line, edgeWidth: 0.2, division: CrestFieldDivision.Barry,
            divisionCount: 6)));

    /// A saffron sun and its burst on terracotta, over a sunset of red
    /// running through tenné into dune.
    public static readonly SpaceHouse Sun = new("sun", "Sun", "CrestSun", HouseLook(
        background: [Tincture.SunGules, Tincture.SunTenne, Tincture.SunDune], accent: [Tincture.SunOr], Tincture.SunTerracotta,
        Arms(CrestBackplate.Circle, CrestSymbol.Sun, CrestTrim.Sunburst, edgeWidth: 0.25),
        backgroundAngle: 160, texture: 0.45));

    /// A bone raven on charcoal, sealed round, over the onyx of the Watch.
    public static readonly SpaceHouse Vigil = new("vigil", "Vigil", "CrestVigil", HouseLook(
        background: [Tincture.VigilOnyx], accent: [Tincture.VigilBone], Tincture.VigilCharcoal,
        Arms(CrestBackplate.Seal, CrestSymbol.Raven, CrestTrim.DoubleRing, edgeWidth: 0.45, trimWeight: 0.9, depth: CrestDepth.None),
        texture: 0.3));

    /// Arma's own arms: a white bird on a navy guidon with a pale in the dark
    /// grey of the Catppuccin Macchiato theme it starts with, wreathed in gold
    /// laurel, in the crest's own colors so the Space's never change them;
    /// over Arma navy, with a gold accent and a red pattern. Its app icon is
    /// the app's own.
    public static readonly SpaceHouse Arma = new("arma", "Arma", "Crest", HouseLook(
        background: [Tincture.ArmaNavy], accent: [Tincture.ArmaGold], Tincture.ArmaRed,
        SpaceCrest.PlainField(CrestBackplate.Flag, CrestSymbol.Sparrow, CrestTrim.Laurel, layers: [0, 1, 2, 4, 3, 5],
            trimWeight: 0.75, chargeScale: 1.15) with {
            Ordinary = CrestOrdinary.Pale,
            Palette = new([
                Tincture.ArmaNavy.Color, Tincture.ArmaNavy.Color, Tincture.ArmaGrey.Color, Tincture.ArmaWhite.Color,
                Tincture.ArmaGold.Color, Tincture.ArmaNavy.Color
            ]),
            EdgeWidth = 0.2,
            Finish = CrestFinish.Flat,
            Depth = CrestDepth.Soft
        }));

    public static IReadOnlyList<SpaceHouse> All { get; } = [Winter, Lion, Storm, Dragon, Meadow, Iron, River, Sun, Vigil, Arma];

    /// The crest a new Space wears: Arma's arms, the guidon with a gold pale
    /// and a red bird in a double gold line, embossed and lifted on Arma
    /// navy, in the crest's own colors so the theme never changes them.
    public static SpaceCrest NewSpaceCrest { get; } = SpaceCrest.PlainField(CrestBackplate.Flag, CrestSymbol.Sparrow,
        CrestTrim.DoubleLine, layers: [0, 1, 2, 4, 3, 5], trimWeight: 0.827, chargeScale: 1.165) with {
        Ordinary = CrestOrdinary.Pale,
        OrdinaryWidth = 1.013,
        Palette = new([
            Tincture.ArmaNavy.Color, new(0.812, 0.82, 0.831), new(0.871, 0.729, 0.318), new(0.749, 0.18, 0.137),
            new(0.863, 0.758, 0.359), new(0.255, 0.271, 0.349)
        ]),
        EdgeWidth = 0.268,
        Finish = CrestFinish.Embossed,
        Depth = CrestDepth.Lifted,
        SealTeeth = 18
    };

    /// The look a new Space wears for `accent`: Arma's own house for the
    /// first accent and every other accent's house colors, each under the
    /// new Space's crest.
    public static SpaceBranding NewSpaceLook(SpaceAccent accent) {
        ArgumentNullException.ThrowIfNull(accent);
        var house = accent == SpaceAccent.All[0] ? Arma.Look : accent.House;
        return house with { Crest = NewSpaceCrest };
    }

    #endregion

    #region Variables

    public string Name { get; }

    /// The house's name in the template gallery.
    [Localized]
    public string Title { get; }

    /// The look a Space starting from the house wears.
    public SpaceBranding Look { get; }

    /// The app icon in the house's colors, by its asset name.
    public string AppIconName { get; }

    #endregion

    #region Constructors

    private SpaceHouse(string name, string title, string appIconName, SpaceBranding look) {
        Name = name;
        Title = title;
        AppIconName = appIconName;
        Look = look;
    }

    #endregion

    #region Actions - Lookup

    public static SpaceHouse? Named(string? name) => All.FirstOrDefault(house => house.Name == name);

    #endregion

    #region Actions - Looks

    /// A house's look: a plain sidebar in its `background` that keeps controls
    /// readable, under a grain of `texture` where the house's material has
    /// one, its `accent` and `pattern`, and its arms. Each well is its
    /// first color running on into the rest along a line toward its angle,
    /// or that one color alone.
    private static SpaceBranding HouseLook(Tincture[] background, Tincture[] accent, Tincture pattern, SpaceCrest arms,
        double backgroundAngle = DownAngle, double accentAngle = DownAngle, double texture = 0) =>
        new(new([background[0].Color, accent[0].Color, pattern.Color]), SpaceBannerPattern.Solid, BannerStrength: 1,
            ReadabilityFade: 0.45, KeepsControlsReadable: true, SpaceThemeMode.Banner, GradientAngle: 0, TextureStrength: texture,
            SpaceIconStyle.LayeredCrest, SymbolColor: null, arms, CrestVocabulary.Studio.Version, FolderColorIntensity: 0,
            SpaceTextColorMode.Automatic, HasCustomAppearance: false,
            ColorGradients: Gradients(Run(background, backgroundAngle), Run(accent, accentAngle)));

    /// The gradient a well of `colors` runs on into after its first, along a
    /// line toward `angle`, or plain for a well of one color.
    private static BrandGradient Run(Tincture[] colors, double angle) => colors.Length < 2 ? BrandGradient.Plain
        : new(new([.. colors.Skip(1).Select(tincture => tincture.Color)]), Kind: null, angle);

    /// The gradients the wells run on into, by slot, with none after the last
    /// that runs on, or null when every well is one color.
    private static PaletteGradients? Gradients(params BrandGradient[] slots) {
        int count = Array.FindLastIndex(slots, slot => !slot.IsPlain) + 1;
        return count == 0 ? null : new(slots[..count]);
    }

    /// A house's arms in the Space's colors: its figure, border and band in the
    /// Accent on a field of the Pattern, which stands it off the sidebar, with
    /// a second field and the edge in the Background.
    private static SpaceCrest Arms(CrestBackplate backplate, CrestSymbol figure, CrestTrim trim, double edgeWidth,
        double chargeScale = 1.2, double trimWeight = 0.75, CrestFinish? finish = null, CrestDepth? depth = null,
        CrestFieldDivision? division = null, int divisionCount = SpaceCrest.DefaultDivisionCount) =>
        SpaceCrest.PlainField(backplate, figure, trim, layers: [Pattern, Background, Accent, Accent, Accent, Background], trimWeight,
            chargeScale) with {
            FieldDivision = division ?? CrestFieldDivision.Plain,
            DivisionCount = divisionCount,
            EdgeWidth = edgeWidth,
            Finish = finish ?? CrestFinish.Flat,
            Depth = depth ?? CrestDepth.Soft
        };

    #endregion
}
