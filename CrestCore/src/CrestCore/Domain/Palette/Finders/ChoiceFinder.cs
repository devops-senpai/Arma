using CrestCore.Contracts;

namespace CrestCore.Domain;

/// What the platform can do from a tool scope, such as @engine: offered only
/// once the person narrowed the palette to that scope, every choice before
/// anything is typed and the ones whose names match after.
internal sealed class ChoiceFinder : PaletteFinder {
    #region Actions - Finding

    internal override IEnumerable<PaletteCandidate> Find(PaletteContext context, PaletteSource source, PaletteQuery query,
        PaletteSuggestions question, bool narrowed) {
        if (!narrowed) yield break;
        foreach (var choice in question.Choices) {
            if (choice.Scope.Source != source) continue;
            int? score = query.IsEmpty ? 0 : query.Score(choice.Name, choice.Detail) ?? query.Abbreviates(choice.Name);
            if (score is not { } matched) continue;
            var row = PaletteRow.Of(PaletteRowKind.Choice, choice.Name, choice.Detail, symbol: choice.Symbol, subject: choice.Id);
            yield return Scored(context, source, row, context.Matched(query, row, matched), place: null, fallback: null);
        }
    }

    #endregion
}
