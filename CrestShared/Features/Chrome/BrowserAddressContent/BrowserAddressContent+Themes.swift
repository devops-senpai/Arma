import SwiftUI

extension BrowserAddressContent {
    // MARK: - Variables

    /// The page's path in the theme's quieter color. Text takes `.secondary`
    /// as its primary color dimmed, not the second level a theme sets, so
    /// the theme's is named.
    var routeStyle: AnyShapeStyle {
        controlColors.secondaryText.map { AnyShapeStyle($0.color) } ?? AnyShapeStyle(.secondary)
    }
}
