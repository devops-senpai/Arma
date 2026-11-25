namespace CrestCore.Contracts;

/// How often a Space asks the person to authenticate before it shows or
/// copies one of its saved passwords: each time, once in a while, or never.
/// Exporting every password always asks, whatever this says. A choice
/// travels as its index in `All`, so `All` is append-only.
public sealed class CredentialAuthentication {
    #region Static Variables

    public static readonly CredentialAuthentication EachTime = new(name: "eachTime", title: "Ask Each Time",
        asksAtAll: true, asksAgainAfterSeconds: 0, confirmsChoosing: false);
    public static readonly CredentialAuthentication Every15Minutes = new(name: "every15Minutes", title: "Ask Every 15 Minutes",
        asksAtAll: true, asksAgainAfterSeconds: 15 * 60, confirmsChoosing: false);
    /// Anyone at the Mac while the person is logged in could copy the Space's
    /// passwords, so a person confirms choosing it.
    public static readonly CredentialAuthentication Never = new(name: "never", title: "Don’t Ask",
        asksAtAll: false, asksAgainAfterSeconds: 0, confirmsChoosing: true);

    public static IReadOnlyList<CredentialAuthentication> All { get; } = [EachTime, Every15Minutes, Never];

    #endregion

    #region Variables

    public string Name { get; }

    /// The choice's name where a person picks it.
    [Localized]
    public string Title { get; }

    /// Whether showing or copying a password asks to authenticate at all.
    public bool AsksAtAll { get; }

    /// How long after the person last authenticated for the Space showing or
    /// copying a password asks again; 0 asks each time.
    public double AsksAgainAfterSeconds { get; }

    /// Whether a person confirms choosing it, for a choice that lowers how
    /// well the Space's passwords are kept.
    public bool ConfirmsChoosing { get; }

    #endregion

    #region Constructors

    private CredentialAuthentication(string name, string title, bool asksAtAll, double asksAgainAfterSeconds,
        bool confirmsChoosing) {
        Name = name;
        Title = title;
        AsksAtAll = asksAtAll;
        AsksAgainAfterSeconds = asksAgainAfterSeconds;
        ConfirmsChoosing = confirmsChoosing;
    }

    #endregion

    #region Actions - Lookup

    public static CredentialAuthentication? Named(string? name) => All.FirstOrDefault(choice => choice.Name == name);

    /// Whether showing or copying a password now asks to authenticate, given
    /// how many seconds ago the person last did for the Space, or null when
    /// they have not since this Mac last slept or locked.
    public bool Asks(double? secondsSinceLastAuthenticated) =>
        AsksAtAll && (secondsSinceLastAuthenticated is not { } since || since < 0 || since >= AsksAgainAfterSeconds);

    #endregion
}
