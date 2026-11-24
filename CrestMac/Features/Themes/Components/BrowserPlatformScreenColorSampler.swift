import AppKit
import SwiftUI

/// The Mac's screen eyedropper beside a color wheel: picks a color from
/// anywhere on screen and hands it to `pick`. The sampler lives as long as
/// the button: one made for the click alone is released as `show` returns,
/// before the loupe appears, and nothing is picked.
struct BrowserPlatformScreenColorSampler: View {
    let pick: (BrandColor) -> Void

    @State private var sampler = NSColorSampler()

    var body: some View {
        Button {
            sampler.show { picked in
                guard let picked = picked?.usingColorSpace(.sRGB) else { return }
                pick(BrandColor(color: Color(nsColor: picked)))
            }
        } label: {
            Image(systemName: "eyedropper")
        }
        .buttonStyle(CrestChromeButtonStyle())
        .help("Pick from Screen")
        .accessibilityLabel("Pick from Screen")
    }
}
