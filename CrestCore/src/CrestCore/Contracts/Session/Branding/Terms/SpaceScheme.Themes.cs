namespace CrestCore.Contracts;

/// The themes Arma ships with, as schemes: a scheme made as a theme also
/// dresses the Space's folders, text, palette, popovers and controls, and may
/// carry a look of its own for dark windows.
public sealed partial class SpaceScheme {
    #region Static Variables

    // Themes Arma ships with, after Arc's sidebar and the Catppuccin palettes
    // (catppuccin.com/palette); Latte / Mocha pairs the light and darkest flavors.
    public static readonly SpaceScheme ArcSky = new("arcSky", "Arc Sky", ThemeLook(
            [new(0.894, 0.937, 0.957), new(0.329, 0.784, 0.945), new(0.761, 0.871, 0.902)],
            strength: 0.8, SpaceTextColorMode.Dark, textureStrength: 1,
            symbol: new(0.122, 0.373, 0.502), new(
                Text: new(new(0, 0.118, 0.165), new(0.482, 0.514, 0.549)),
                Folders: new(new(0.898, 0.957, 0.984), new(0.518, 0.812, 0.941), new(0.055, 0.443, 0.584),
                    new(0.518, 0.812, 0.941), 0.384, Overrides: null),
                CommandPalette: new(new(new(0.988, 0.992, 0.996), 0.94, new(0, 0.118, 0.165)),
                    new(new(0.988, 0.992, 0.996), 0.94, new(0, 0.118, 0.165))),
                Popovers: new(new(0.914, 0.949, 0.965), new(0, 0, 0), new(0, 0, 0), new(0.043, 0.365, 0.478), 1,
                    new(0.804, 0.835, 0.851), new(0.757, 0.82, 0.965)),
                Controls: new(new(1, 1, 1), 0.7, new(0, 0.118, 0.165), new(0.31, 0.353, 0.392)))),
        darkLook: ThemeLook(
            [new(0, 0.118, 0.165), new(0.329, 0.784, 0.945), new(0.165, 0.545, 0.655)],
            strength: 0.8, SpaceTextColorMode.Light, textureStrength: 1,
            symbol: new(0.863, 0.953, 0.988), new(
                Text: new(new(0.82, 0.902, 0.925), new(0.482, 0.514, 0.549)),
                Folders: new(new(0.114, 0.29, 0.361), new(0.165, 0.545, 0.655), new(0.518, 0.812, 0.941),
                    new(0.114, 0.29, 0.361), 0.384, Overrides: null),
                CommandPalette: new(new(new(0, 0.059, 0.082), 0.94, new(0.82, 0.902, 0.925)),
                    new(new(0, 0.059, 0.082), 0.94, new(0.82, 0.902, 0.925))),
                Popovers: new(new(0.043, 0.153, 0.2), new(0.82, 0.902, 0.925), new(0.608, 0.737, 0.784),
                    new(0.518, 0.812, 0.941), 1, new(0.071, 0.224, 0.29), new(0.165, 0.545, 0.655)),
                Controls: new(new(0.071, 0.224, 0.29), 0.9, new(0.82, 0.902, 0.925), new(0.608, 0.737, 0.784)))));

    public static readonly SpaceScheme ArcBlush = new("arcBlush", "Arc Blush", ThemeLook(
            [new(0.976, 0.902, 0.918), new(0.992, 0.631, 0.678), new(0.949, 0.788, 0.827)],
            strength: 0.8, SpaceTextColorMode.Dark, textureStrength: 1,
            symbol: new(0.62, 0.11, 0.212), new(
                Text: new(new(0.224, 0, 0.043), null),
                Folders: new(new(1, 0.941, 0.949), new(0.992, 0.631, 0.678), new(0.761, 0.165, 0.271), new(0.992, 0.631, 0.678),
                    0.428, Overrides: null),
                CommandPalette: new(new(new(0.996, 0.988, 0.992), 0.94, new(0.224, 0, 0.043)),
                    new(new(0.996, 0.988, 0.992), 0.94, new(0.224, 0, 0.043))),
                Popovers: new(new(0.992, 0.945, 0.953), new(0.224, 0, 0.043), new(0.478, 0.227, 0.282), new(0.69, 0.129, 0.235),
                    1, new(0.973, 0.843, 0.871), new(0.992, 0.631, 0.678)),
                Controls: new(new(1, 0.941, 0.953), 0.75, new(0.224, 0, 0.043), new(0.478, 0.227, 0.282)))),
        darkLook: ThemeLook(
            [new(0.224, 0, 0.043), new(0.992, 0.631, 0.678), new(0.812, 0.224, 0.376)],
            strength: 0.8, SpaceTextColorMode.Light, textureStrength: 1,
            symbol: new(1, 0.922, 0.929), new(
                Text: new(new(0.961, 0.839, 0.871), null),
                Folders: new(new(0.353, 0.102, 0.157), new(0.812, 0.224, 0.376), new(0.992, 0.631, 0.678),
                    new(0.353, 0.102, 0.157), 0.384, Overrides: null),
                CommandPalette: new(new(new(0.11, 0, 0.024), 0.94, new(0.961, 0.839, 0.871)),
                    new(new(0.11, 0, 0.024), 0.94, new(0.961, 0.839, 0.871))),
                Popovers: new(new(0.165, 0.035, 0.063), new(0.961, 0.839, 0.871), new(0.831, 0.604, 0.659),
                    new(0.992, 0.631, 0.678), 1, new(0.29, 0.078, 0.125), new(0.812, 0.224, 0.376)),
                Controls: new(new(0.29, 0.078, 0.125), 0.9, new(0.961, 0.839, 0.871), new(0.831, 0.604, 0.659)))));

    public static readonly SpaceScheme Latte = new("catppuccinLatte", "Catppuccin Latte", ThemeLook(
            [new(0.937, 0.945, 0.961), new(0.533, 0.224, 0.937), new(0.737, 0.753, 0.8)],
            strength: 1, SpaceTextColorMode.Dark, textureStrength: 0,
            symbol: new(0.533, 0.224, 0.937), new(
                Text: new(new(0.298, 0.31, 0.412), new(0.424, 0.435, 0.522)),
                Folders: new(new(0.016, 0.647, 0.898), new(0.675, 0.69, 0.745), new(0.447, 0.529, 0.992),
                    new(0.016, 0.647, 0.898), 0.34, Overrides: null),
                CommandPalette: new(new(new(0.937, 0.945, 0.961), 0.92, new(0.298, 0.31, 0.412)),
                    new(new(0.937, 0.945, 0.961), 0.92, new(0.298, 0.31, 0.412))),
                Popovers: new(new(0.937, 0.945, 0.961), new(0.298, 0.31, 0.412), new(0.361, 0.373, 0.467),
                    new(0.533, 0.224, 0.937), 1, new(0.902, 0.914, 0.937), new(0.447, 0.529, 0.992)),
                Controls: new(new(0.902, 0.914, 0.937), 0.85, new(0.298, 0.31, 0.412), new(0.361, 0.373, 0.467)))));

    public static readonly SpaceScheme LatteMocha = new("catppuccinLatteMocha", "Catppuccin Latte / Mocha", ThemeLook(
            [new(0.937, 0.945, 0.961), new(0.533, 0.224, 0.937), new(0.737, 0.753, 0.8)],
            strength: 1, SpaceTextColorMode.Dark, textureStrength: 0,
            symbol: new(0.533, 0.224, 0.937), new(
                Text: new(new(0.298, 0.31, 0.412), new(0.424, 0.435, 0.522)),
                Folders: new(new(0.118, 0.4, 0.961), new(0.675, 0.69, 0.745), new(0.612, 0.627, 0.69), new(0.118, 0.4, 0.961),
                    0.34, Overrides: null),
                CommandPalette: new(new(new(0.937, 0.945, 0.961), 0.92, new(0.298, 0.31, 0.412)),
                    new(new(0.937, 0.945, 0.961), 0.92, new(0.298, 0.31, 0.412))),
                Popovers: new(new(0.937, 0.945, 0.961), new(0.298, 0.31, 0.412), new(0.361, 0.373, 0.467),
                    new(0.533, 0.224, 0.937), 1, new(0.902, 0.914, 0.937), new(0.447, 0.529, 0.992)),
                Controls: new(new(0.902, 0.914, 0.937), 0.85, new(0.298, 0.31, 0.412), new(0.361, 0.373, 0.467)))),
        darkLook: ThemeLook(
            [new(0.118, 0.118, 0.18), new(0.796, 0.651, 0.969), new(0.271, 0.278, 0.353)],
            strength: 1, SpaceTextColorMode.Light, textureStrength: 0,
            symbol: new(0.796, 0.651, 0.969), new(
                Text: new(new(0.804, 0.839, 0.957), new(0.651, 0.678, 0.784)),
                Folders: new(new(0.796, 0.651, 0.969), new(0.345, 0.357, 0.439), new(0.424, 0.439, 0.525),
                    new(0.796, 0.651, 0.969), 0.34, Overrides: null),
                CommandPalette: new(new(new(0.118, 0.118, 0.18), 0.92, new(0.804, 0.839, 0.957)),
                    new(new(0.118, 0.118, 0.18), 0.92, new(0.804, 0.839, 0.957))),
                Popovers: new(new(0.118, 0.118, 0.18), new(0.804, 0.839, 0.957), new(0.651, 0.678, 0.784),
                    new(0.796, 0.651, 0.969), 1, new(0.192, 0.196, 0.267), new(0.498, 0.518, 0.612)),
                Controls: new(new(0.192, 0.196, 0.267), 0.9, new(0.804, 0.839, 0.957), new(0.651, 0.678, 0.784)))));

    public static readonly SpaceScheme Frappe = new("catppuccinFrappe", "Catppuccin Frappé", ThemeLook(
            [new(0.188, 0.204, 0.275), new(0.792, 0.62, 0.902), new(0.318, 0.341, 0.427)],
            strength: 1, SpaceTextColorMode.Light, textureStrength: 0,
            symbol: new(0.792, 0.62, 0.902), new(
                Text: new(new(0.776, 0.816, 0.961), new(0.647, 0.678, 0.808)),
                Folders: new(new(0.506, 0.784, 0.745), new(0.384, 0.408, 0.502), new(0.18, 0.188, 0.231),
                    new(0.506, 0.784, 0.745), 0.34, Overrides: null),
                CommandPalette: new(new(new(0.188, 0.204, 0.275), 0.92, new(0.776, 0.816, 0.961)),
                    new(new(0.188, 0.204, 0.275), 0.92, new(0.776, 0.816, 0.961))),
                Popovers: new(new(0.188, 0.204, 0.275), new(0.776, 0.816, 0.961), new(0.647, 0.678, 0.808),
                    new(0.506, 0.784, 0.745), 1, new(0.255, 0.271, 0.349), new(0.514, 0.545, 0.655)),
                Controls: new(new(0.255, 0.271, 0.349), 0.9, new(0.776, 0.816, 0.961), new(0.71, 0.749, 0.886)))));

    public static readonly SpaceScheme Macchiato = new("catppuccinMacchiato", "Catppuccin Macchiato", ThemeLook(
            [new(0.141, 0.153, 0.227), new(0.776, 0.627, 0.965), new(0.286, 0.302, 0.392)],
            strength: 1, SpaceTextColorMode.Light, textureStrength: 0,
            symbol: new(0.776, 0.627, 0.965), new(
                Text: new(new(0.792, 0.827, 0.961), new(0.647, 0.678, 0.796)),
                Folders: new(new(0.718, 0.741, 0.973), new(0.357, 0.376, 0.471), new(0.431, 0.451, 0.553),
                    new(0.718, 0.741, 0.973), 0.34, Overrides: null),
                CommandPalette: new(new(new(0.141, 0.153, 0.227), 0.92, new(0.792, 0.827, 0.961)),
                    new(new(0.141, 0.153, 0.227), 0.92, new(0.792, 0.827, 0.961))),
                Popovers: new(new(0.141, 0.153, 0.227), new(0.792, 0.827, 0.961), new(0.647, 0.678, 0.796),
                    new(0.718, 0.741, 0.973), 1, new(0.212, 0.227, 0.31), new(0.431, 0.451, 0.553)),
                Controls: new(new(0.212, 0.227, 0.31), 0.9, new(0.792, 0.827, 0.961), new(0.647, 0.678, 0.796)))));

    public static readonly SpaceScheme Mocha = new("catppuccinMocha", "Catppuccin Mocha", ThemeLook(
            [new(0.118, 0.118, 0.18), new(0.796, 0.651, 0.969), new(0.271, 0.278, 0.353)],
            strength: 1, SpaceTextColorMode.Light, textureStrength: 0,
            symbol: new(0.796, 0.651, 0.969), new(
                Text: new(new(0.961, 0.878, 0.863), new(0.651, 0.678, 0.784)),
                Folders: new(new(0.98, 0.702, 0.529), new(0.573, 0.592, 0.729), new(0.067, 0.067, 0.067),
                    new(0.98, 0.702, 0.529), 0.398, Overrides: null),
                CommandPalette: new(new(new(0.118, 0.118, 0.18), 0.92, new(0.804, 0.839, 0.957)),
                    new(new(0.118, 0.118, 0.18), 0.92, new(0.804, 0.839, 0.957))),
                Popovers: new(new(0.118, 0.118, 0.18), new(0.804, 0.839, 0.957), new(0.651, 0.678, 0.784),
                    new(0.98, 0.702, 0.529), 1, new(0.192, 0.196, 0.267), new(0.498, 0.518, 0.612)),
                Controls: new(new(0.192, 0.196, 0.267), 0.9, new(0.804, 0.839, 0.957), new(0.651, 0.678, 0.784)))));

    /// The themes, in the order the gallery lists them after Crest's own schemes.
    private static IReadOnlyList<SpaceScheme> Themes => [ArcSky, ArcBlush, Latte, LatteMocha, Frappe, Macchiato, Mocha];

    #endregion

    #region Variables

    /// The look a Space starting from the scheme wears while windows are dark,
    /// or null to wear <see cref="Look"/> in both.
    public SpaceBranding? DarkLook { get; }

    #endregion

    #region Constructors

    private SpaceScheme(string name, string title, SpaceBranding look, SpaceBranding darkLook) : this(name, title, look) {
        DarkLook = darkLook;
    }

    #endregion

    #region Actions - Looks

    /// A theme's look: its colors as a solid banner at `strength` with no
    /// readability fade, its text in `text`, and the Space's icon in place of a
    /// crest, drawn in `symbol`, dressed in `dress`.
    private static SpaceBranding ThemeLook(BrandColor[] colors, double strength, SpaceTextColorMode text, double textureStrength,
        BrandColor symbol, SpaceDress dress) =>
        new(new(colors), SpaceBannerPattern.Solid, strength, ReadabilityFade: 0, KeepsControlsReadable: false, SpaceThemeMode.Banner,
            GradientAngle: 45, textureStrength, SpaceIconStyle.SimpleSymbol, symbol, SpaceBranding.Neutral.Crest,
            CrestVocabulary.Customization.Version, FolderColorIntensity: 0, text, HasCustomAppearance: false, Dress: dress);

    #endregion
}
