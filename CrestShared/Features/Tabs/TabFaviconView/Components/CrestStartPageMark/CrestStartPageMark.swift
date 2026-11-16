import SwiftUI

struct CrestStartPageMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let palette = CrestStartPageMarkPalette(colorScheme: colorScheme)

            ZStack {
                RoundedRectangle(
                    cornerRadius: side * CrestStartPageMarkMetrics.cornerRadiusRatio,
                    style: .continuous
                )
                .fill(palette.background)

                // Arma's banner stands where Crest's drawn one did. The image
                // is a tight crop of the banner, so it keeps a margin.
                Image("ArmaMark")
                    .resizable()
                    .scaledToFit()
                    .padding(side * 0.1)
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .overlay {
                RoundedRectangle(
                    cornerRadius: side * CrestStartPageMarkMetrics.cornerRadiusRatio,
                    style: .continuous
                )
                .strokeBorder(
                    .primary.opacity(CrestStartPageMarkMetrics.borderOpacity),
                    lineWidth: CrestStartPageMarkMetrics.borderWidth
                )
            }
        }
    }
}

#if DEBUG
    #Preview("Component") {
        CrestStartPageMark().frame(width: 80, height: 80).padding()
    }
#endif
