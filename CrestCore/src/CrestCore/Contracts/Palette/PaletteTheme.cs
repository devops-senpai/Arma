namespace CrestCore.Contracts;

/// A saved theme the palette may put on the Space it speaks for, named as
/// the platform keeps it, with what it shows beneath the name.
public sealed record PaletteTheme(Guid Id, string Name, string Detail);
