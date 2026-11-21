import Foundation

/// What a theme adds to setup: a bundled theme the Spaces setup makes wear,
/// and Arc's Spaces each given a crest of their own.
extension BrowserOnboardingFlow {
    // MARK: - Actions - Themes

    /// Dresses the Spaces setup holds in `theme`, each keeping its crest and
    /// icon as the library dresses a Space, with the theme's picture where
    /// the Space finds it, so the preview shows the theme; every Space wears
    /// it once setup finishes.
    func chooseTheme(_ theme: BrowserBundledTheme) {
        guard !isImportSelectionLocked else { return }
        self.theme = theme
        themedSpaceIDs = []
        guard let look = theme.theme else { return }
        for space in manualSetup.spaces { dress(space.spaceID, in: look) }
    }

    /// Dresses Space `spaceID` in the chosen theme the first time setup opens
    /// it, as a Space added after the choice comes in its accent's own look;
    /// a Space dressed already keeps whatever the person made of it since.
    func dressAddedSpace(_ spaceID: UUID) {
        guard let look = theme?.theme, !themedSpaceIDs.contains(spaceID) else { return }
        dress(spaceID, in: look)
    }

    private func dress(_ spaceID: UUID, in look: CrestTheme) {
        themedSpaceIDs.insert(spaceID)
        let branding = manualSetup.brandingBinding(for: spaceID)
        var identity = branding.wrappedValue
        identity.keepIdentityColors()
        guard let dressed = try? identity.dressed(in: BrowserThemeLibrary.withoutIdentity(look)) else { return }
        branding.wrappedValue = dressed.normalized()
        try? BrowserThemeLibrary.applyBackgroundImage(look.backgroundImage, to: spaceID, in: .shared)
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
