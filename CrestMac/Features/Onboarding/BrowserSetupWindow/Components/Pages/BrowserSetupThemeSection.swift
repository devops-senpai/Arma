import SwiftUI

/// The themes Arma ships, as a section over a Space's colors in setup: each
/// a short sidebar in the theme's Background with a dot of its Accent, named
/// underneath, as the palettes under it are shown. Choosing one dresses every
/// Space setup makes in it, which the preview shows at once, and the Spaces
/// made after setup wear it too.
struct BrowserSetupThemeSection: View {
    // MARK: - Variables

    let flow: BrowserOnboardingFlow

    // MARK: - Actions - Drawing

    var body: some View {
        Section("Theme") {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: BrowserSpacePalettePickerMetrics.column), spacing: 6)],
                spacing: 6
            ) {
                ForEach(BrowserBundledTheme.all) { offered in
                    CrestSelectableCard(
                        isSelected: offered.id == flow.theme?.id, accessibilityLabel: Text(offered.name),
                        density: .compact, tint: nil
                    ) {
                        flow.chooseTheme(offered)
                    } content: {
                        VStack(spacing: CrestSpacing.extraSmall) {
                            swatch(offered)
                            Text(offered.name)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .help(Text(offered.pitch))
                    .accessibilityIdentifier("setup-theme-\(offered.id.uuidString)")
                }
            }
            .padding(.vertical, CrestSpacing.extraExtraSmall)
            .accessibilityIdentifier("setup-themes")
        }
    }

    /// A short sidebar in the theme's Background, its Accent a dot where a
    /// Space's icon sits: a neutral look dressed in the theme.
    private func swatch(_ offered: BrowserBundledTheme) -> some View {
        let look = offered.theme.flatMap { try? SpaceBranding.neutral.dressed(in: $0) } ?? .neutral
        return RoundedRectangle(cornerRadius: BrowserSpacePalettePickerMetrics.cornerRadius, style: .continuous)
            .fill(look.backgroundFill.style)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(look.accentFill.style)
                    .frame(
                        width: BrowserSpacePalettePickerMetrics.accentDot,
                        height: BrowserSpacePalettePickerMetrics.accentDot
                    )
                    .padding(.leading, BrowserSpacePalettePickerMetrics.accentInset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: BrowserSpacePalettePickerMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(CrestBrandTheme.line, lineWidth: CrestLayout.hairline)
            }
            .frame(height: BrowserSpacePalettePickerMetrics.swatchHeight)
    }
}
