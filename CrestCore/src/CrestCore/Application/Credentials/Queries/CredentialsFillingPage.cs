using CrestCore.Application;

namespace CrestCore.Contracts;

/// Which of the origins passwords were saved for, `Saved`, fill a page at
/// `Page` (see `CredentialOrigin.Fills`), where the password saved for the
/// origin at each index of `ReachingSubdomains` also fills the hosts under it
/// (see `CredentialOrigin.FillsSubdomain`). A saved origin may be spelled as
/// an earlier release kept it; the page's must be canonical. A question
/// carries at most `CredentialOrigin.MaximumFillCandidates` saved origins, so
/// a caller splits a longer list. It reads nothing the app holds.
public sealed record CredentialsFillingPage(CredentialOrigin Page, IReadOnlyList<CredentialOrigin> Saved,
    IReadOnlyList<int> ReachingSubdomains) : Query<CredentialFills> {
    #region Variables

    internal override bool AnsweredUnderLock => false;

    #endregion

    #region Actions - Answering

    internal override CredentialFills Answer(CrestApp app) {
        var page = Page.Validated();
        if (Saved.Count > CredentialOrigin.MaximumFillCandidates)
            throw new Rejected(new CredentialRecordLimitReached(CredentialOrigin.MaximumFillCandidates));
        var reaching = ReachingSubdomains.ToHashSet();
        return new([.. Saved.Select((saved, index) => saved.Fills(page) || reaching.Contains(index) && saved.FillsSubdomain(page))]);
    }

    #endregion
}
