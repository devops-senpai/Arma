import SwiftUI

extension View {
    // MARK: - Actions - Appearance

    /// A popover opened from the sidebar inherits the sidebar's theme text
    /// color, meant for the sidebar's own background; its symbols and labels
    /// take the system's colors instead, on a popover in the sidebar's look
    /// (`colorScheme`, which a Space's theme may make dark while the system
    /// is light), so they read whatever the theme.
    func browserReadableInSidebarLook(_ colorScheme: ColorScheme) -> some View {
        foregroundStyle(.primary)
            .preferredColorScheme(colorScheme)
    }
}
