import SwiftUI

extension BrowserCrestStudioStep {
    // MARK: - Static Variables

    /// The rest of the window the Space dresses, beyond its crest and sidebar.
    static let other = BrowserCrestStudioStep(
        kind: .other, name: "other", title: "Other", symbol: "slider.horizontal.3", isCrestOnly: false,
        summary: { branding in
            if branding.commandPalette?.isTinted == true { return "Tinted palette" }
            if branding.popoverBackgroundColor != nil || branding.popoverTextColor != nil { return "Tinted popovers" }
            return branding.controlsFillColor != nil || branding.controlsTextColor != nil
                ? "Tinted controls" : "Default"
        })
}
