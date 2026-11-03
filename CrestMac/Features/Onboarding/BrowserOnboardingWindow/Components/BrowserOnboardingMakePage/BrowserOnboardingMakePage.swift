import SwiftUI

/// Making a Space yours: its crest large with its name under it, the crest
/// again at the sidebar's sizes on the theme's sidebar, so the person sees
/// how it reads small, and one sheet of what a first run changes on the
/// crest. The sidebar's colors belong to the theme. The full Forge waits in
/// Settings.
struct BrowserOnboardingMakePage: View {
    let look: SetupLook
    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    @Binding var name: String
    /// The Space as its icon draws it, shown large.
    let identity: BrowserSpaceIdentity
    /// The theme setup dresses the Spaces in, which the small window wears,
    /// or nil for the Space's own look.
    var theme: CrestTheme? = nil
    /// The Spaces being made, as chips, or nil for a page that makes one
    /// Space alone.
    var picker: BrowserOnboardingMakePicker? = nil
    /// Why the last edit was refused, when it was.
    var failure: BrowserOnboardingFailureText? = nil
    let back: BrowserOnboardingBackAction?
    let advanceTitle: Text
    let advance: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let inset = BrowserOnboardingStageMetrics.pageInset(for: geometry.size.width)
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 20) {
                    BrowserOnboardingHeadline("Make it yours")
                    Spacer()
                    if look.kind == .heraldic {
                        Button("Shuffle", systemImage: "shuffle") {
                            branding = branding.shuffledCrest()
                        }
                        .buttonStyle(.crestSecondary)
                        .help("A new crest for this Space")
                        .accessibilityIdentifier("space-forge-shuffle")
                    }
                    if let picker {
                        BrowserOnboardingMakeChips(picker: picker)
                    }
                }
                .padding(.horizontal, inset)
                .padding(.top, 8)
                .padding(.bottom, 20)

                GeometryReader { body in
                    HStack(alignment: .top, spacing: BrowserOnboardingMakeMetrics.spacing) {
                        preview
                            .frame(width: previewWidth(in: body.size.width), height: body.size.height)
                        sheet
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, inset)
                .padding(.bottom, 8)

                BrowserOnboardingFooter(back: back) {
                    HStack(spacing: 22) {
                        if let failure {
                            BrowserOnboardingFailureMessage(message: failure)
                                .font(CrestTypography.sans(12, weight: .medium))
                                .foregroundStyle(.red)
                                .lineLimit(2)
                                .accessibilityIdentifier("onboarding-workflow-error")
                        }
                        BrowserOnboardingContinueButton(advanceTitle, action: advance)
                            .accessibilityIdentifier("space-setup-continue")
                    }
                }
            }
        }
    }

    /// The width the window takes of `available`: under half, and never
    /// narrower than its sidebar and a page beside it.
    private func previewWidth(in available: CGFloat) -> CGFloat {
        max(BrowserOnboardingMakeMetrics.minimumPreviewWidth, available * 0.44)
    }

    /// The Space's crest on the sidebar the chosen theme gives it: large,
    /// and again at the sizes the sidebar draws it, so the person sees how it
    /// contrasts; its name under the box.
    private var preview: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            crestBox
            VStack(spacing: 4) {
                BrowserInlineSpaceName(
                    name: $name, size: 24, titleFont: CrestTypography.sans(24, weight: .semibold)
                )
                .fixedSize()
                Text("Click the name to rename")
                    .font(CrestTypography.sans(11))
                    .foregroundStyle(CrestBrandTheme.textDisplay.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var crestBox: some View {
        VStack(spacing: 28) {
            BrowserSpaceIdentityIcon(identity: identity, size: BrowserOnboardingMakeMetrics.crestSize)
                .frame(width: BrowserOnboardingMakeMetrics.crestSize, height: BrowserOnboardingMakeMetrics.crestSize)
            HStack(spacing: 24) {
                ForEach(BrowserOnboardingMakeMetrics.sidebarCrestSizes, id: \.self) { size in
                    BrowserSpaceIdentityIcon(identity: identity, size: size)
                        .frame(width: size, height: size)
                }
            }
        }
        .padding(BrowserOnboardingMakeMetrics.crestBoxPadding)
        .background {
            BrowserSpaceBannerBackground(branding: windowBranding)
        }
        .clipShape(.rect(cornerRadius: CrestRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CrestRadius.card, style: .continuous)
                .strokeBorder(.primary.opacity(0.14), lineWidth: CrestLayout.hairline)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 12)
        .environment(\.colorScheme, windowBranding.colorScheme(over: .dark))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The crest on the theme's sidebar, large and at sidebar sizes")
    }

    /// The Space's look dressed in the setup's theme, as its sidebar will
    /// wear it once setup finishes.
    private var windowBranding: SpaceBranding {
        guard let theme, let dressed = try? branding.dressed(in: theme) else { return branding }
        return dressed
    }

    @ViewBuilder private var sheet: some View {
        switch look.kind {
        case .heraldic:
            BrowserOnboardingHeraldicSheet(branding: $branding, symbol: $symbol)
        case .modern:
            BrowserOnboardingModernSheet(branding: $branding, symbol: $symbol)
        }
    }
}

/// The Spaces a page makes, as chips with one to add.
struct BrowserOnboardingMakePicker {
    let spaces: [BrowserSpaceIdentity]
    let selectedID: UUID?
    let select: (UUID) -> Void
    let add: () -> Void
    /// Removes a Space the setup made, or nil for one it cannot remove.
    let remove: (UUID) -> (() -> Void)?
}

private struct BrowserOnboardingMakeChips: View {
    let picker: BrowserOnboardingMakePicker

    /// The chips in a row where they fit the header, and in a row that
    /// scrolls sideways where a setup has made more Spaces than fit.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            chips
            ScrollView(.horizontal) { chips }
                .scrollIndicators(.hidden)
                .frame(maxWidth: BrowserOnboardingMakeMetrics.chipsWidth)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spaces")
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(picker.spaces) { space in
                BrowserOnboardingSpaceChip(space: space, isSelected: space.id == picker.selectedID) {
                    picker.select(space.id)
                }
                .contextMenu {
                    if let remove = picker.remove(space.id) {
                        Button("Remove Space", role: .destructive, action: remove)
                    }
                }
            }
            Button(action: picker.add) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CrestBrandTheme.textDisplay)
                    .frame(width: 34, height: 34)
                    .background(CrestBrandPalette.paper.opacity(0.1), in: .circle)
                    .overlay { Circle().strokeBorder(CrestBrandTheme.line, lineWidth: CrestLayout.hairline) }
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .help("New Space")
            .accessibilityLabel("Add a Space")
            .accessibilityIdentifier("space-customization-add")
        }
    }
}

/// One Space as a chip: its icon and name, lit when it is the one shown.
struct BrowserOnboardingSpaceChip: View {
    let space: BrowserSpaceIdentity
    let isSelected: Bool
    let select: () -> Void

    init(space: some BrowserSpaceIdentifying, isSelected: Bool, select: @escaping () -> Void) {
        self.space = space.identity
        self.isSelected = isSelected
        self.select = select
    }

    var body: some View {
        Button(action: select) {
            BrowserSpaceIdentityLabel(identity: space, iconSize: 18)
                .font(CrestTypography.sans(13, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? CrestBrandPalette.ink : CrestBrandTheme.textDisplay)
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 34)
                .background(isSelected ? CrestBrandPalette.paper : CrestBrandPalette.paper.opacity(0.1), in: .capsule)
                .overlay {
                    Capsule().strokeBorder(CrestBrandTheme.line, lineWidth: isSelected ? 0 : CrestLayout.hairline)
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

enum BrowserOnboardingMakeMetrics {
    /// The window never narrows past its sidebar and a page beside it.
    static let minimumPreviewWidth: CGFloat = 520
    /// Between the window and the sheet.
    static let spacing: CGFloat = 48
    /// The most of the header the Space chips take once they scroll.
    static let chipsWidth: CGFloat = 520
    /// The crest, large, above the Space's name.
    static let crestSize: CGFloat = 200
    /// The sizes the sidebar draws a crest: a Space row, the switcher, and
    /// the Space header.
    static let sidebarCrestSizes: [CGFloat] = [18, 22, 32]
    /// The room around the crests inside their theme-colored box.
    static let crestBoxPadding: CGFloat = 36
    /// A choice tile on the sheet.
    static let tileSize: CGFloat = 52
    static let tileArtworkSize: CGFloat = 40
    static let swatchSize: CGFloat = 34
}
