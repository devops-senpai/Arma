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
                                .foregroundStyle(CrestColor.danger)
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
        case .simple:
            BrowserOnboardingSimpleSheet(branding: $branding, symbol: $symbol)
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

/// The Spaces being made as a rail of chips, with one to add. The rail
/// scrolls sideways where a setup has made more Spaces than fit the header.
private struct BrowserOnboardingMakeChips: View {
    let picker: BrowserOnboardingMakePicker

    var body: some View {
        CrestSpaceChipRail(
            spaces: CrestSpaceIdentity.list(picker.spaces),
            selection: Binding(
                get: { picker.selectedID },
                set: { if let id = $0 { picker.select(id) } }),
            add: CrestSpaceChipAddAction(
                title: "New Space", accessibilityIdentifier: "space-customization-add", perform: picker.add),
            commands: { space in picker.remove(space.id).map { [.remove($0)] } ?? [] }
        )
        .frame(maxWidth: BrowserOnboardingMakeMetrics.chipsWidth)
        .accessibilityLabel("Spaces")
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
    /// The artwork of a choice tile on the sheet.
    static let tileArtworkSize: CGFloat = 40
    static let swatchSize: CGFloat = 34
}
