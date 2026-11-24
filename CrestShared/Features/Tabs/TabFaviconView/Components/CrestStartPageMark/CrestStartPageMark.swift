import SwiftUI

/// Arma's mark: its banner on a tile in the brand's cream or ink, under a rim
/// one device pixel wide.
struct CrestStartPageMark: View {
    // MARK: - Variables

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    // MARK: - Actions - Drawing

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = RoundedRectangle(
                cornerRadius: side * CrestStartPageMarkMetrics.cornerRadiusRatio, style: .continuous)
            ZStack {
                tile.fill(colorScheme == .dark ? CrestBrandPalette.ink : CrestBrandPalette.creamComponents.color)
                // The image is a tight crop of the banner, so it keeps a margin.
                Image("ArmaMark")
                    .resizable()
                    .scaledToFit()
                    .padding(side * 0.1)
                tile.strokeBorder(
                    .primary.opacity(CrestOpacity.border), lineWidth: 1 / displayScale)
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

#if DEBUG
    #Preview("Component") {
        HStack(spacing: 24) {
            CrestStartPageMark().frame(width: 128, height: 128)
            CrestStartPageMark().frame(width: 32, height: 32)
        }
        .padding()
    }
#endif
