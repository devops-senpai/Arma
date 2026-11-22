import SwiftUI

/// The welcome, filling setup's window on Crest's paper: Arma's banner,
/// large, its name lettered under it, a line on who it is for, and the way
/// in. Nothing else shows while it does, so the way in is the one thing to
/// do.
struct BrowserSetupLanding<Leading: View, Forward: View>: View {
    // MARK: - Variables

    /// The steps the walk takes, ending with starting Crest.
    let steps: [BrowserSetupStep]
    let welcome: BrowserOnboardingWelcomeAction
    /// Opens a step from its chip, when the welcome leads straight to one.
    let open: ((BrowserSetupStep) -> Void)?
    /// What the welcome offers beside the way in, if anything.
    let leading: Leading
    /// The way in.
    let forward: Forward

    // MARK: - Initializers

    init(
        steps: [BrowserSetupStep], welcome: BrowserOnboardingWelcomeAction,
        open: ((BrowserSetupStep) -> Void)? = nil, @ViewBuilder leading: () -> Leading,
        @ViewBuilder forward: () -> Forward
    ) {
        self.steps = steps
        self.welcome = welcome
        self.open = open
        self.leading = leading()
        self.forward = forward()
    }

    // MARK: - Actions - Drawing

    var body: some View {
        VStack(spacing: BrowserSetupLandingMetrics.spacing) {
            Image("ArmaMark")
                .resizable()
                .scaledToFit()
                .frame(height: BrowserSetupLandingMetrics.markHeight)
                .shadow(
                    color: CrestBrandPalette.ink.opacity(BrowserSetupLandingMetrics.markShadow),
                    radius: BrowserSetupLandingMetrics.markShadowRadius, y: BrowserSetupLandingMetrics.markShadowOffset
                )
                .accessibilityHidden(true)
            Text(verbatim: "Arma")
                .font(CrestTypography.lettering(BrowserSetupLandingMetrics.titleSize))
                .accessibilityAddTraits(.isHeader)
            Text("A browser for cool people.")
                .font(CrestTypography.serif(BrowserSetupLandingMetrics.bodySize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: BrowserSetupLandingMetrics.bodyWidth)
            if welcome.opensCrest {
                Text("Your Spaces came in from iCloud, ready to use.")
                    .font(CrestTypography.sans(BrowserSetupLandingMetrics.noteSize, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: BrowserSetupLandingMetrics.bodyWidth)
            }
            HStack(spacing: CrestSpacing.medium) {
                leading
                forward
            }
            .controlSize(.extraLarge)
            .padding(.top, CrestSpacing.small)
        }
        .padding(BrowserSetupLandingMetrics.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum BrowserSetupLandingMetrics {
    static let spacing: CGFloat = 18
    /// The banner stands nearly half as tall as the window at its smallest.
    static let markHeight: CGFloat = 340
    static let markShadow = 0.3
    static let markShadowRadius: CGFloat = 20
    static let markShadowOffset: CGFloat = 12
    static let titleSize: CGFloat = 112
    static let bodySize: CGFloat = 28
    static let noteSize: CGFloat = 16
    static let bodyWidth: CGFloat = 560
    static let inset: CGFloat = 48
}
