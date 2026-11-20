import Foundation

/// The parts of a look's dress as settings of the look itself, so the Crest
/// Studio's key paths, a theme file and the views that draw a part each read
/// and write one without unwrapping the dress. Writing a part makes the part
/// it lives in; the core drops a part that sets nothing when it normalizes
/// the look.
extension SpaceBranding {
    // MARK: - Variables

    /// The one color the sidebar's text reads in, or nil to follow the text
    /// color mode.
    var sidebarTextColor: BrandColor? {
        get { dress?.text?.color }
        set { editText { $0.color = newValue } }
    }

    /// The color the sidebar's quieter text reads in, such as New Tab and
    /// Clear, or nil to dim the sidebar's text as the system does.
    var sidebarSecondaryTextColor: BrandColor? {
        get { dress?.text?.secondaryColor }
        set { editText { $0.secondaryColor = newValue } }
    }

    /// The color a folder without one of its own wears, or nil for the
    /// default folder color.
    var folderColor: BrandColor? {
        get { dress?.folders?.color }
        set { editFolders { $0.color = newValue } }
    }

    /// That folder's back face, or nil to shade its front.
    var folderBackColor: BrandColor? {
        get { dress?.folders?.backColor }
        set { editFolders { $0.backColor = newValue } }
    }

    /// The line around that folder, or nil for none.
    var folderOutlineColor: BrandColor? {
        get { dress?.folders?.outlineColor }
        set { editFolders { $0.outlineColor = newValue } }
    }

    /// The color that tints a folder's rows while it is open, hovered or
    /// chosen, or nil for the folder's own color.
    var folderHighlightColor: BrandColor? {
        get { dress?.folders?.highlightColor }
        set { editFolders { $0.highlightColor = newValue } }
    }

    /// How opaque that tint is, or nil to leave it to the folder color
    /// intensity, as before a look could choose it.
    var folderHighlightOpacity: Double? {
        get { dress?.folders?.highlightOpacity }
        set { editFolders { $0.highlightOpacity = newValue } }
    }

    /// The colors single folders wear in place of the Space's, by path.
    var folderOverrides: FolderColorOverrides? {
        get { dress?.folders?.overrides }
        set { editFolders { $0.overrides = newValue } }
    }

    /// The command palette's card over the Space, or nil for the system
    /// material alone.
    var commandPalette: SpacePaletteLook? {
        get { dress?.commandPalette }
        set { editDress { $0.commandPalette = newValue } }
    }

    var popoverBackgroundColor: BrandColor? {
        get { dress?.popovers?.backgroundColor }
        set { editPopovers { $0.backgroundColor = newValue } }
    }

    var popoverTextColor: BrandColor? {
        get { dress?.popovers?.textColor }
        set { editPopovers { $0.textColor = newValue } }
    }

    var popoverSecondaryTextColor: BrandColor? {
        get { dress?.popovers?.secondaryTextColor }
        set { editPopovers { $0.secondaryTextColor = newValue } }
    }

    var popoverAccentColor: BrandColor? {
        get { dress?.popovers?.accentColor }
        set { editPopovers { $0.accentColor = newValue } }
    }

    var popoverAccentOpacity: Double {
        get { dress?.popovers?.accentOpacity ?? 1 }
        set { editPopovers { $0.accentOpacity = newValue } }
    }

    var popoverButtonColor: BrandColor? {
        get { dress?.popovers?.buttonColor }
        set { editPopovers { $0.buttonColor = newValue } }
    }

    var popoverButtonOutlineColor: BrandColor? {
        get { dress?.popovers?.buttonOutlineColor }
        set { editPopovers { $0.buttonOutlineColor = newValue } }
    }

    var controlsFillColor: BrandColor? {
        get { dress?.controls?.fillColor }
        set { editControls { $0.fillColor = newValue } }
    }

    var controlsFillOpacity: Double {
        get { dress?.controls?.fillOpacity ?? 1 }
        set { editControls { $0.fillOpacity = newValue } }
    }

    var controlsTextColor: BrandColor? {
        get { dress?.controls?.textColor }
        set { editControls { $0.textColor = newValue } }
    }

    var controlsSecondaryTextColor: BrandColor? {
        get { dress?.controls?.secondaryTextColor }
        set { editControls { $0.secondaryTextColor = newValue } }
    }

    // MARK: - Mutators

    private mutating func editDress(_ change: (inout SpaceDress) -> Void) {
        var edited = dress ?? SpaceDress(text: nil, folders: nil, commandPalette: nil, popovers: nil, controls: nil)
        change(&edited)
        dress = edited
    }

    private mutating func editText(_ change: (inout SidebarTextDress) -> Void) {
        editDress { dress in
            var text = dress.text ?? SidebarTextDress(color: nil, secondaryColor: nil)
            change(&text)
            dress.text = text
        }
    }

    private mutating func editFolders(_ change: (inout FolderDress) -> Void) {
        editDress { dress in
            var folders =
                dress.folders
                ?? FolderDress(
                    color: nil, backColor: nil, outlineColor: nil, highlightColor: nil, highlightOpacity: nil,
                    overrides: nil)
            change(&folders)
            dress.folders = folders
        }
    }

    private mutating func editPopovers(_ change: (inout PopoverDress) -> Void) {
        editDress { dress in
            var popovers =
                dress.popovers
                ?? PopoverDress(
                    backgroundColor: nil, textColor: nil, secondaryTextColor: nil, accentColor: nil, accentOpacity: 1,
                    buttonColor: nil, buttonOutlineColor: nil)
            change(&popovers)
            dress.popovers = popovers
        }
    }

    private mutating func editControls(_ change: (inout ControlsDress) -> Void) {
        editDress { dress in
            var controls =
                dress.controls ?? ControlsDress(fillColor: nil, fillOpacity: 1, textColor: nil, secondaryTextColor: nil)
            change(&controls)
            dress.controls = controls
        }
    }
}
