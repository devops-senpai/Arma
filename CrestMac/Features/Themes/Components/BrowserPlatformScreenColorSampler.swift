import AppKit
import SwiftUI

/// The Mac's screen eyedropper beside a color wheel: picks a color from
/// anywhere on screen and hands it to `pick`.
struct BrowserPlatformScreenColorSampler: View {
    let pick: (BrandColor) -> Void

    var body: some View {
        Button {
            NSColorSampler().show { picked in
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
