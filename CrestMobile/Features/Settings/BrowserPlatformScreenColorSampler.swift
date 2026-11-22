import SwiftUI

/// The phone and tablet have no screen eyedropper, so a color wheel offers
/// none.
struct BrowserPlatformScreenColorSampler: View {
    let pick: (BrandColor) -> Void

    var body: some View {
        EmptyView()
    }
}
