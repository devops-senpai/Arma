import Foundation

/// What a theme adds to the Space commands: new Spaces made in the device's
/// default theme, a look of their own for dark windows, and folders that wear
/// their Space's folder colors again.
extension BrowserStore {
    // MARK: - Actions - Space Themes

    /// Makes a Space as `CreateSpace` does, wearing the theme the device chose
    /// for new Spaces when it chose one. A private Space keeps the look that
    /// says it is private.
    func themedCreateSpace(workspaceID: UUID, windowID: UUID, spaceID: UUID) -> CreateSpace {
        let theme = isPrivateBrowsing ? nil : BrowserDefaultSpaceLook.shared
        return CreateSpace(
            workspaceID: workspaceID, windowID: windowID, spaceID: spaceID, look: theme?.look,
            darkLook: theme?.look == nil ? nil : theme?.darkLook)
    }

    /// Whether the new Space `spaceID` was made in the device's default theme,
    /// in which case the shell keeps it wearing the theme and the customization
    /// style leaves it as it is.
    func madeInDefaultTheme(_ spaceID: UUID) -> Bool {
        let theme = BrowserDefaultSpaceLook.shared
        guard !isPrivateBrowsing, theme.look != nil else { return false }
        theme.spaceMade?(spaceID)
        return true
    }

    /// Gives the Space a look of its own for dark windows, or nil to wear one look in both.
    func updateSpaceDarkBranding(
        _ branding: SpaceBranding?,
        in spaceID: UUID
    ) {
        sendSpaceSettings(
            SetSpaceDarkBranding(
                workspaceID: profileSettingsBrowser.family.workspaceID, spaceID: spaceID,
                branding: branding))
    }

    /// Lets the folder wear its Space's folder colors again.
    @discardableResult
    func clearFolderColor(_ folderID: UUID, matching assignment: BrowserSpaceRuntimeAssignment) -> Bool {
        guard let space = spaceModel(matching: assignment), space.folders.contains(folderID) else { return false }
        return family.send(
            SetFolderColor(
                workspaceID: family.workspaceID, spaceID: assignment.spaceID, folderID: folderID, color: nil),
            from: self)
    }
}
