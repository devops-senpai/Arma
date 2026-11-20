import SwiftUI

extension BrowserOnboardingWindowPreview {
    // MARK: - Actions - Presentation

    /// What the page card is filled with: paper, or the window background
    /// as a dark window draws it while a dark appearance is followed. The
    /// card sits in the look's own scheme, which a light look keeps light
    /// over a dark window, so the background is drawn in the dark one.
    func pageFill(_ shape: some Shape, over colorScheme: ColorScheme) -> some View {
        let followsDark = pageFollowsAppearance && colorScheme == .dark
        let fill = followsDark ? AnyShapeStyle(CrestColor.windowBackground) : AnyShapeStyle(CrestBrandPalette.paper)
        return shape.fill(fill).environment(\.colorScheme, .dark)
    }
}
