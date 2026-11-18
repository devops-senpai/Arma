import SwiftUI

/// The look the Spaces setup makes wear: Crest's own banners and crests, a
/// modern gradient and icon, or a simple tinted sidebar with dots for Spaces,
/// each shown as a window. Choosing one restyles the stage and every preview
/// from here on, and gives Crest's customization that style.
struct BrowserOnboardingLookPage: View {
    let look: SetupLook
    let choose: (SetupLook) -> Void
    let back: BrowserOnboardingBackAction
    let continueSetup: () -> Void
    /// The themes offered over the looks, under a heading of their own, or
    /// nil for the looks alone.
    var themes: BrowserOnboardingThemeChoice? = nil

    /// The size each window takes: an equal share of the stage's width in
    /// the stage's columns, less the gaps, and no taller than lets every
    /// row stand on the stage at once, so the page scrolls only on a short
    /// stage.
    private func cardSize(in stage: CGSize) -> CGSize {
        let metrics = BrowserOnboardingLookMetrics.self
        let columns = metrics.columns(for: stage.width)
        let width = min(
            (stage.width - metrics.spacing * CGFloat(columns - 1)) / CGFloat(columns), metrics.maximumWidth)
        let rows = CGFloat(rowCount(in: columns))
        let headings = themes == nil ? 0 : metrics.headingHeight * 2 + metrics.sectionSpacing
        let rowHeight = (stage.height - headings - metrics.rowSpacing * (rows - 1)) / rows - metrics.captionHeight
        let height = min(width * metrics.ratio, max(rowHeight, metrics.minimumHeight))
        return CGSize(width: min(width, height / metrics.ratio), height: height)
    }

    /// How many rows the cards take in `columns`: the themes' rows, where
    /// themes are offered, and the looks'.
    private func rowCount(in columns: Int) -> Int {
        let looks = (SetupLook.all.count + columns - 1) / columns
        guard themes != nil else { return looks }
        return (BrowserBundledTheme.all.count + columns - 1) / columns + looks
    }

    var body: some View {
        VStack(spacing: 0) {
            BrowserOnboardingHeadline("Pick your look")
                .padding(.top, 22)
            GeometryReader { geometry in
                let size = cardSize(in: geometry.size)
                let columns = [
                    GridItem(
                        .adaptive(minimum: size.width, maximum: size.width),
                        spacing: BrowserOnboardingLookMetrics.spacing, alignment: .top)
                ]
                ScrollView {
                    VStack(alignment: .leading, spacing: BrowserOnboardingLookMetrics.sectionSpacing) {
                        if let themes {
                            BrowserOnboardingLookSection("Arma Themes") {
                                LazyVGrid(
                                    columns: columns, alignment: .leading,
                                    spacing: BrowserOnboardingLookMetrics.rowSpacing
                                ) {
                                    BrowserOnboardingThemeCards(choice: themes, size: size)
                                }
                            }
                        }
                        BrowserOnboardingLookSection(themes == nil ? nil : "Crest Themes") {
                            LazyVGrid(
                                columns: columns, alignment: .leading, spacing: BrowserOnboardingLookMetrics.rowSpacing
                            ) {
                                ForEach(SetupLook.all, id: \.self) { offered in
                                    BrowserOnboardingLookCard(
                                        look: offered, isSelected: offered == selectedLook, size: size
                                    ) {
                                        choose(offered)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, BrowserOnboardingStageMetrics.pageInset)
            .padding(.vertical, 16)
            .onAppear(perform: BrowserOnboardingThemeCards.preparePictures)
            BrowserOnboardingFooter(back: back) {
                BrowserOnboardingContinueButton(action: continueSetup)
                    .accessibilityIdentifier("onboarding-look-continue")
            }
        }
    }
}

/// One look as a sidebar beside a page, named underneath.
private struct BrowserOnboardingLookCard: View {
    let look: SetupLook
    let isSelected: Bool
    let size: CGSize
    let select: () -> Void

    /// How far the window is drawn down from the size it is measured at, so
    /// a narrow card shows the whole window rather than a cut of it.
    private var scale: CGFloat {
        min(1, size.width / BrowserOnboardingLookMetrics.windowWidth)
    }

    var body: some View {
        VStack(spacing: BrowserOnboardingLookMetrics.captionSpacing) {
            Button(action: select) {
                Color.clear
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        BrowserOnboardingWindowPreview(
                            branding: look.previewBranding, symbol: look.previewSymbol,
                            name: String(localized: "Personal"),
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
            .accessibilityLabel(Text(look.title))
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("onboarding-look-\(look.name)")
            BrowserOnboardingLookCaption(Text(look.title), width: size.width)
        }
    }
}

#if DEBUG
    #Preview("Look") {
        BrowserOnboardingStage(step: .look, branding: SetupLook.heraldic.previewBranding) {
            BrowserOnboardingLookPage(
                look: .heraldic, choose: { _ in }, back: BrowserOnboardingBackAction(closes: false, action: {}),
                continueSetup: {})
        }
        .frame(width: 1440, height: 900)
    }
#endif

enum BrowserOnboardingLookMetrics {
    static let spacing: CGFloat = 28
    /// Between the rows of a section's cards.
    static let rowSpacing: CGFloat = 16
    /// Between the Arma Themes and Crest Themes sections.
    static let sectionSpacing: CGFloat = 20
    /// A section's heading and the gap under it.
    static let headingHeight: CGFloat = 30
    /// Between a window and its name.
    static let captionSpacing: CGFloat = 10
    /// The name under each window, two lines at most, and the gap over it.
    static let captionHeight: CGFloat = 56
    /// A window's height as a share of its width.
    static let ratio: CGFloat = 0.82
    /// The least a window is drawn down to before the page scrolls instead.
    static let minimumHeight: CGFloat = 100
    static let maximumWidth: CGFloat = 420
    /// The width a look's window is measured at before it is drawn down.
    static let windowWidth: CGFloat = 620

    /// How many cards a row holds on a stage `width` wide: five on a wide
    /// stage, four on a narrower one.
    static func columns(for width: CGFloat) -> Int {
        width >= 1100 ? 5 : 4
    }

    /// The size a card's name is set at: smaller under a narrow card, so a
    /// theme's name fits its two lines.
    static func titleSize(for width: CGFloat) -> CGFloat {
        min(20, max(14, width / 9))
    }
}

/// A card's name under its window, within the window's width.
struct BrowserOnboardingLookCaption: View {
    let title: Text
    let width: CGFloat

    init(_ title: Text, width: CGFloat) {
        self.title = title
        self.width = width
    }

    var body: some View {
        title
            .font(CrestTypography.display(BrowserOnboardingLookMetrics.titleSize(for: width)))
            .foregroundStyle(CrestBrandTheme.textDisplay)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(width: width)
    }
}
