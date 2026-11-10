import SwiftUI

/// What a first run changes on a modern Space: its icon. Its colors belong
/// to the theme it wears, which Settings › Themes edits.
struct BrowserOnboardingModernSheet: View {
    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    @State private var choosesEmoji = false

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
        BrowserOnboardingMakeSection("Icon") {
            HStack(spacing: 12) {
                BrowserSystemSymbolPicker(
                    selection: Binding(
                        get: { BrowserIconSymbol.emoji(from: symbol) == nil ? symbol : "" },
                        set: { wearIcon($0) }))
                BrowserArtworkPickerButton(
                    title: "Emoji",
                    detail: BrowserIconSymbol.emoji(from: symbol) == nil
                        ? Text("Choose an emoji") : Text("Change emoji")
                ) {
                    choosesEmoji = true
                } artwork: {
                    if let emoji = BrowserIconSymbol.emoji(from: symbol) {
                        Text(emoji)
                    } else {
                        Image(systemName: "face.smiling")
                    }
                }
                .accessibilityLabel("Choose Emoji")
                .browserIconCustomizationPopover(
                    .init(
                        isPresented: $choosesEmoji, title: "Space Icon",
                        currentEmoji: BrowserIconSymbol.emoji(from: symbol),
                        setEmoji: { wearIcon(BrowserIconSymbol.symbol(forEmoji: $0)) }))
            }
            .frame(maxWidth: 520)
        }
    }

    /// Gives the Space `symbol` as a plain icon, which a Space that came with
    /// a crest then shows in its place.
    private func wearIcon(_ symbol: String) {
        self.symbol = symbol
        if branding.iconStyle != .simpleSymbol {
            $branding.editorUpdate {
                $0.iconStyle = .simpleSymbol
                $0.hasCustomAppearance = true
            }
        }
    }
}
