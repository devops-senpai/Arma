import SwiftUI

/// The theme setup offers beside Crest's looks: the one chosen, or nil for a
/// look alone, and choosing another.
struct BrowserOnboardingThemeChoice {
    let theme: BrowserBundledTheme?
    let choose: (BrowserBundledTheme) -> Void
}

/// The themes Arma ships with, as cards under the look page's Arma Themes
/// heading: each the heraldic look dressed in the theme under Arma's crest,
/// as a small window, named underneath. Choosing one has the Spaces setup
/// makes wear it once setup finishes, and new Spaces after them.
struct BrowserOnboardingThemeCards: View {
    // MARK: - Variables

    let choice: BrowserOnboardingThemeChoice
    /// The size each card takes, the same as a look's.
    let size: CGSize

    @State private var library = BrowserThemeLibrary.shared

    // MARK: - Actions - Presentation

    var body: some View {
        ForEach(BrowserBundledTheme.all) { offered in
            card(offered)
        }
    }

    private func card(_ offered: BrowserBundledTheme) -> some View {
        let isSelected = offered.id == choice.theme?.id
        let scale = min(1, size.width / BrowserOnboardingLookMetrics.windowWidth)
        let look = SetupLook.heraldic
        let branding = offered.theme.flatMap { try? look.previewBranding.dressed(in: $0) } ?? look.previewBranding
        return VStack(spacing: BrowserOnboardingLookMetrics.captionSpacing) {
            Button {
                choice.choose(offered)
            } label: {
                Color.clear
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        BrowserOnboardingWindowPreview(
                            branding: branding, symbol: look.previewSymbol, name: String(localized: "Personal"),
                            backdrop: offered.theme?.backgroundImage == nil
                                ? nil : (offered.id, library.previewBackdrops),
                            spaceIcons: BrowserCustomizationStyle.matching(look).spaceIcons, companionLook: look
                        ) {
                            EmptyView()
                        }
                        .frame(width: size.width / scale, height: size.height / scale)
                        .scaleEffect(scale)
                    }
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: BrowserOnboardingWindowPreviewMetrics.cornerRadius, style: .continuous
                        )
                        .strokeBorder(isSelected ? CrestBrandPalette.butter : .clear, lineWidth: 4)
                    }
                    .contentShape(
                        .rect(cornerRadius: BrowserOnboardingWindowPreviewMetrics.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(Text(offered.pitch))
            .accessibilityLabel(Text(offered.name))
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("onboarding-theme-\(offered.id.uuidString)")
            BrowserOnboardingLookCaption(Text(verbatim: offered.name), width: size.width)
        }
    }

    // MARK: - Actions - Pictures

    /// Puts the picture of each theme that has one where the cards draw it.
    static func preparePictures() {
        for offered in BrowserBundledTheme.all { BrowserThemeLibrary.shared.preparePreview(offered.id) }
    }
}

/// One heading of the look page, over the cards it groups; without a title,
/// the cards alone.
struct BrowserOnboardingLookSection<Content: View>: View {
    let title: LocalizedStringKey?
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(CrestTypography.sans(13, weight: .bold))
                    .foregroundStyle(CrestBrandTheme.textSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .accessibilityElement(children: .contain)
    }
}

extension BrowserOnboardingLookPage {
    // MARK: - Variables

    /// The look shown as chosen: none while a theme is.
    var selectedLook: SetupLook? { themes?.theme == nil ? look : nil }
}
