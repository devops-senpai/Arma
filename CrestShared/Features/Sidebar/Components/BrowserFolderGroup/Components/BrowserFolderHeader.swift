import SwiftUI

/// The folder's own row: the control a reader opens it with, wearing the
/// surface, the drag source, and the drop feedback that belong to the folder
/// rather than to its contents.
struct BrowserFolderHeader: View {
    @Environment(BrowserSidebarInteractionState.self) private var sidebarInteraction

    let configuration: BrowserFolderGroupConfiguration
    let interaction: BrowserFolderGroupInteractionContext

    private var folder: FolderStateModel { configuration.folder }
    private var tabScale: Double { BrowserDeviceAppearanceStore.shared.tabScale }

    private var plateReach: CGFloat { BrowserSidebarMetrics.folderPlateReach(tabScale: tabScale) }

    /// The gap between two rows' plates, half of which the header keeps here.
    private var rowSeparation: CGFloat {
        CGFloat(
            BrowserSidebarDensity(tabScale).rowSeparation(
                hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all))
    }

    /// The height of one tab row at the sidebar's density.
    private var tabRowHeight: CGFloat {
        BrowserSidebarDensity(tabScale).rowHeight(
            base: CrestLayout.sidebarRowHeight, touch: !configuration.headerMetrics.usesFixedRowHeight)
    }

    var body: some View {
        BrowserFolderHeaderControl(
            configuration: configuration,
            interaction: interaction
        )
        .accessibilityLabel("\(folder.shownTitle) folder")
        .accessibilityValue(
            BrowserChromeAccessibility.folderValue(
                isExpanded: interaction.isExpanded.wrappedValue
            )
        )
        .accessibilityHint(
            interaction.isExpanded.wrappedValue
                ? "Collapses this folder"
                : "Expands this folder"
        )
        .modifier(BrowserFolderSelectionAccessibility(folderID: folder.id, browser: configuration.browser))
        // Inside the folder's padding, as a Split View's header is inside its own.
        .padding(.horizontal, BrowserSidebarMetrics.layerInset + BrowserSidebarMetrics.containerPadding)
        // The separation a tab row keeps, so the two stand alike.
        .padding(
            .vertical,
            BrowserSidebarDensity(tabScale).rowSeparation(
                hasBorders: BrowserDeviceAppearanceStore.shared.tabs.borders == .all) / 2
        )
        // The Space's tab backing, in the shape and height a tab row's plate
        // takes: the header is shorter than a tab row by the folder's own
        // padding, so the plate reaches past it to a whole row, centered.
        .background {
            BrowserSidebarTabBackingPlate(
                cornerRadius: BrowserSidebarMetrics.layerCornerRadius(depth: configuration.depth)
            )
            .frame(height: tabRowHeight)
            .padding(.horizontal, BrowserSidebarMetrics.layerInset)
        }
        // An open folder's first row sits right under the header, past the
        // padding a closed folder keeps there, so the header keeps the room
        // its plate reaches into and the row below stays a row's gap away.
        .padding(.bottom, interaction.isExpanded.wrappedValue ? plateReach + rowSeparation / 2 : 0)
        .modifier(
            BrowserTabSelectionTarget(
                tabID: nil, browser: configuration.browser,
                assignment: configuration.folderRuntimeAssignment.spaceAssignment,
                isEnabled: configuration.isAvailableForDisplay
                    && interaction.editingFolderRequest.wrappedValue != configuration.folderRuntimeAssignment,
                folderID: folder.id)
        )
        .browserFolderDraggable(
            folder: folder,
            profileID: configuration.profileID,
            spaceID: configuration.spaceID,
            dragState: sidebarInteraction.folderDragState,
            reorder: BrowserSidebarReorderContext(
                browser: configuration.browser,
                spaceAccess: configuration.spaceAccess,
                state: sidebarInteraction.sidebarReorderState
            ),
            isEnabled: interaction.editingFolderRequest.wrappedValue
                != configuration.folderRuntimeAssignment
                && configuration.isAvailableForDisplay,
            requiresSelectedSpace: true
        )
        // The one thing a section's zone cannot say: that releasing *here* files
        // the lifted folder inside this one rather than beside it. The seam
        // above the header is already drawn by the row's own reorder indicator,
        // on every shell, so the header carries only the nesting answer.
        .overlay {
            BrowserFolderNestDropHighlight(
                state: sidebarInteraction.sidebarReorderState, target: .folder(folder.id), depth: configuration.depth)
        }
    }
}
