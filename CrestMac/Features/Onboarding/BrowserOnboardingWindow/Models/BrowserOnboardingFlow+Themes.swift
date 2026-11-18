import Foundation

/// What a theme adds to setup: a bundled theme the Spaces setup makes wear,
/// and Arc's Spaces each given a crest of their own.
extension BrowserOnboardingFlow {
    // MARK: - Actions - Themes

    /// Gives the Spaces setup makes from here on the heraldic look dressed in
    /// `theme`, which each wears once setup finishes.
    func chooseTheme(_ theme: BrowserBundledTheme) {
        guard !isImportSelectionLocked else { return }
        chooseLook(.heraldic)
        self.theme = theme
    }

    /// Dresses every Space setup made, and the Spaces made after it, in the
    /// theme chosen in setup, if one was.
    func dressSpacesInChosenTheme() {
        guard let theme else { return }
        BrowserThemeLibrary.shared.chooseDefaultTheme(theme.id)
        for space in browser.spaceModels {
            _ = BrowserThemeLibrary.shared.choose(theme.id, for: space.id, in: browser)
        }
    }

    // MARK: - Actions - Import

    /// Arc's Spaces carry no crest, so each one comes in wearing a crest of
    /// its own rather than all wearing the same one. The review publishes on
    /// the next turn of the main actor.
    func shuffleReviewedCrestsSoon() {
        Task { @MainActor [weak self] in self?.shuffleReviewedCrests() }
    }

    /// Gives every reviewed Space a crest shuffled from the Forge's parts, as
    /// the crest page's Shuffle does, which the person can still change.
    /// Whether the look counts as the person's own stays as the import set it,
    /// so the theme setup chose still dresses the Space.
    private func shuffleReviewedCrests() {
        for review in reviewSpaces {
            let current = review.customization
            var branding = current.branding.shuffledCrest()
            branding.hasCustomAppearance = current.branding.hasCustomAppearance
            customize(
                review.id,
                as: SpaceCustomization(
                    name: current.name, symbol: current.symbol, accent: current.accent, branding: branding))
        }
    }
}
