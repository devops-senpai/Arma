namespace CrestCore.Contracts;

/// A narrowing of the palette to one kind of result, entered by typing its
/// `Keyword` and pressing Tab: it then lists every match of that kind, and
/// nothing else, until the person leaves it. A scope travels as its index in
/// `All`, so `All` is append-only.
public sealed class PaletteScope {
    #region Static Variables

    public static readonly PaletteScope Tabs = new(name: "tabs", keyword: "@tabs", title: "Tabs", symbol: "square.on.square",
        source: PaletteSource.OpenTabs);
    public static readonly PaletteScope Saved = new(name: "saved", keyword: "@saved", title: "Pinned & Saved", symbol: "pin",
        source: PaletteSource.Saved);
    public static readonly PaletteScope History = new(name: "history", keyword: "@history", title: "History", symbol: "clock",
        source: PaletteSource.History);
    public static readonly PaletteScope Actions = new(name: "actions", keyword: "@actions", title: "Actions", symbol: "command",
        source: PaletteSource.Actions);
    public static readonly PaletteScope Spaces = new(name: "spaces", keyword: "@spaces", title: "Spaces", symbol: "square.stack",
        source: PaletteSource.Spaces);

    public static readonly PaletteScope Themes = new(name: "themes", keyword: "@themes", title: "Themes", symbol: "paintpalette",
        source: PaletteSource.Themes);

    public static readonly PaletteScope Extensions = new(name: "extensions", keyword: "@extensions", title: "Extensions",
        symbol: "puzzlepiece.extension", source: PaletteSource.Extensions);
    public static readonly PaletteScope Engine = new(name: "engine", keyword: "@engine", title: "Engine",
        symbol: "arrow.triangle.swap", source: PaletteSource.Engine);
    public static readonly PaletteScope Developer = new(name: "developer", keyword: "@developer", title: "Developer",
        symbol: "hammer", source: PaletteSource.Developer);
    public static readonly PaletteScope CommandLine = new(name: "cli", keyword: "@cli", title: "Command Line",
        symbol: "terminal", source: PaletteSource.CommandLine);
    public static readonly PaletteScope Update = new(name: "update", keyword: "@update", title: "Software Update",
        symbol: "arrow.down.circle", source: PaletteSource.Update);

    public static IReadOnlyList<PaletteScope> All { get; } =
        [Tabs, Saved, History, Actions, Spaces, Themes, Extensions, Engine, Developer, CommandLine, Update];

    #endregion

    #region Variables

    public string Name { get; }

    /// What a person types before Tab to enter the scope.
    public string Keyword { get; }

    /// What the scope's chip says.
    [Localized]
    public string Title { get; }

    /// The SF Symbol the scope's chip wears.
    public string Symbol { get; }

    /// The only kind of result the scope offers.
    public PaletteSource Source { get; }

    #endregion

    #region Constructors

    private PaletteScope(string name, string keyword, string title, string symbol, PaletteSource source) {
        Name = name;
        Keyword = keyword;
        Title = title;
        Symbol = symbol;
        Source = source;
    }

    #endregion

    #region Actions - Lookup

    public static PaletteScope? Named(string? name) => All.FirstOrDefault(scope => scope.Name == name);

    /// The scope whose keyword is `word`, ignoring case, or null.
    public static PaletteScope? Keyed(string word) =>
        All.FirstOrDefault(scope => string.Equals(scope.Keyword, word, StringComparison.OrdinalIgnoreCase));

    #endregion
}
