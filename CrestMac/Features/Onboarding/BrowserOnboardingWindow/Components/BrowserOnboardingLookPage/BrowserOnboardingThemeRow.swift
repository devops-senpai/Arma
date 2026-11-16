import SwiftUI

/// The themes Arma ships with, as a row of small windows under the look
/// page's looks: each the heraldic look dressed in the theme, named
/// underneath. Choosing one has the Spaces setup makes wear it once setup
/// finishes, and new Spaces after them.
struct BrowserOnboardingThemeRow: View {
    // MARK: - Static Variables

    private static let cardSize = CGSize(width: 150, height: 104)
    /// The width each window is measured at before it is drawn down.
    private static let windowWidth: CGFloat = 620

    // MARK: - Variables

    /// The theme chosen, or nil for a look alone.
    let theme: BrowserBundledTheme?
    let choose: (BrowserBundledTheme) -> Void

    // MARK: - Actions - Presentation

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: CrestSpacing.large) {
                ForEach(BrowserBundledTheme.all) { offered in
                    card(offered)
                }
            }
            .padding(.horizontal, BrowserOnboardingStageMetrics.pageInset)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-themes")
    }

    private func card(_ offered: BrowserBundledTheme) -> some View {
        let isSelected = offered.id == theme?.id
        let scale = Self.cardSize.width / Self.windowWidth
        let look = SetupLook.heraldic
        let branding = offered.theme.flatMap { try? look.previewBranding.dressed(in: $0) } ?? look.previewBranding
        return VStack(spacing: CrestSpacing.small) {
            Button {
                choose(offered)
            } label: {
                Color.clear
                    .frame(width: Self.cardSize.width, height: Self.cardSize.height)
                    .overlay {
                        BrowserOnboardingWindowPreview(
                            branding: branding, symbol: look.previewSymbol, name: String(localized: "Personal"),
                            spaceIcons: BrowserCustomizationStyle.matching(look).spaceIcons, companionLook: look
                        ) {
                            EmptyView()
                        }
                        .frame(width: Self.cardSize.width / scale, height: Self.cardSize.height / scale)
                        .scaleEffect(scale)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: CrestRadius.compact, style: .continuous)
                            .strokeBorder(isSelected ? CrestBrandPalette.butter : .clear, lineWidth: 3)
                    }
                    .contentShape(.rect(cornerRadius: CrestRadius.compact, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(Text(offered.pitch))
            .accessibilityLabel(Text(offered.name))
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            Text(offered.name)
                .font(CrestTypography.display(15))
                .foregroundStyle(CrestBrandTheme.textDisplay)
        }
    }
}

extension BrowserOnboardingLookPage {
    // MARK: - Variables

    /// The look shown as chosen: none while a theme is.
    var selectedLook: SetupLook? { themes?.theme == nil ? look : nil }
}
