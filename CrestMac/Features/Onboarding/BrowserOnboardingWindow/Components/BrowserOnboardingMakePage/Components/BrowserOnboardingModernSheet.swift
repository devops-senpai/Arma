import SwiftUI

/// What a first run changes on a modern Space: its icon. Its colors belong
/// to the theme it wears, which Settings › Themes edits.
struct BrowserOnboardingModernSheet: View {
    @Binding var branding: SpaceBranding
    @Binding var symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            icon
            Spacer(minLength: 0)
            Text("Colors and patterns: Settings › Themes.")
                .font(CrestTypography.sans(12, weight: .medium))
                .foregroundStyle(CrestBrandTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Sections

    private var icon: some View {
        BrowserOnboardingIconSection(branding: $branding, symbol: $symbol)
    }
}
