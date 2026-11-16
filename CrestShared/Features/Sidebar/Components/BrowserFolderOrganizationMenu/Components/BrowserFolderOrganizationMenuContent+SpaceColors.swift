import SwiftUI

/// Lets a folder that wears colors of its own, or ones its Space's theme keeps
/// for its path, wear the Space's folder colors again.
extension BrowserFolderOrganizationMenuContent {
    // MARK: - Variables

    /// The colors the Space's shown look keeps for this folder's path.
    private var folderOverride: FolderColorOverride? {
        context.space.settings.shownLook.folderOverride(of: folder, in: context.space)
    }

    /// Whether the folder wears colors other than its Space's folder colors.
    private var wearsOwnColors: Bool {
        folderOverride != nil || folder.color.map({ $0 != .folderDefault }) ?? false
    }

    @ViewBuilder var useSpaceFolderColorsButton: some View {
        if wearsOwnColors {
            Button("Use Space Folder Colors", systemImage: "arrow.uturn.backward") {
                performIfCurrent(useSpaceFolderColors)
            }
        }
    }

    // MARK: - Actions - Colors

    /// Drops this folder's path from the Space's shown look and any color the
    /// folder holds itself, so it wears the Space's folder colors again.
    private func useSpaceFolderColors() {
        let space = context.space
        let browser = context.browser
        if folderOverride != nil {
            let path = space.folderPath(of: folder)
            let look = space.settings.shownLook.withFolderOverride(path) {
                $0 = FolderColorOverride(path: path, color: nil, backColor: nil, outlineColor: nil)
            }
            if BrowserDeviceAppearanceStore.shared.shownColorScheme == .dark, space.settings.darkBranding != nil {
                browser.updateSpaceDarkBranding(look.normalized(), in: space.id)
            } else {
                browser.updateSpaceBranding(look.normalized(), in: space.id)
            }
        }
        if folder.color.map({ $0 != .folderDefault }) ?? false {
            browser.clearFolderColor(folder.id, matching: assignment.spaceAssignment)
        }
    }
}
