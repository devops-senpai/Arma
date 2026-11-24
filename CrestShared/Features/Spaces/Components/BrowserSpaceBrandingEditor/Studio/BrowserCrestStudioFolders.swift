import SwiftUI

/// The Space's folder colors: the color a folder without its own wears, the
/// color of its back face, the line drawn around it, and the color of the
/// tint its rows take while it is open, hovered or chosen. How strong that
/// tint is stays with the Folder colors slider, Crest's own, so the theme has
/// one control for it. Its Reset puts them back to the starting look's.
struct BrowserCrestStudioFolders: View {
    let context: BrowserCrestStudioContext

    // A chosen color is never the default, whatever look the Space opened with.
    private var color: CrestSettingValue<BrandColor?> { context.setting(\.folderColor, default: nil) }
    private var backColor: CrestSettingValue<BrandColor?> { context.setting(\.folderBackColor, default: nil) }
    /// No outline unless one is chosen.
    private var outlineColor: CrestSettingValue<BrandColor?> { context.setting(\.folderOutlineColor, default: nil) }
    /// The folder's own color tints its rows unless a highlight is chosen.
    private var highlightColor: CrestSettingValue<BrandColor?> {
        context.setting(\.folderHighlightColor, default: nil)
    }
    private var resets: [CrestResettableSetting] {
        [
            color.resettable("Folder color"), backColor.resettable("Back color"),
            outlineColor.resettable("Outline color"), highlightColor.resettable("Highlight color"),
        ]
    }

    var body: some View {
        Section {
            rows
        } header: {
            HStack {
                Text("Folders")
                Spacer()
                BrowserCrestStudioResetButton(title: "Folders", settings: resets)
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        BrowserCrestStudioColorPickerRow(title: "Folder color", value: color, fallback: .folderDefault)
        BrowserCrestStudioColorPickerRow(
            title: "Back color", value: backColor, fallback: context.value.resolvedFolderColor.folderBackShade)
        BrowserCrestStudioColorPickerRow(
            title: "Outline color", value: outlineColor, fallback: context.value.resolvedFolderColor.folderBackShade)
        BrowserCrestStudioColorPickerRow(
            title: "Highlight color", value: highlightColor, fallback: context.value.resolvedFolderColor)
    }
}
