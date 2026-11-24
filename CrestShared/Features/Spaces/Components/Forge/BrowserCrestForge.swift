import SwiftUI

// MARK: - Types

/// The looks a Space's Crest Studio can put back. The Forge keeps one, and
/// shares it with the step pages it opens on a phone, so a drag on any page is
/// one change to undo and Undo on any page steps back through the same past.
struct BrowserCrestForgeHistory {
    // MARK: - Static Variables

    static let limit = 40

    // MARK: - Variables

    private var looks: [SpaceBranding] = []
    /// The look a drag started from; the drag ends as one change from it.
    private(set) var editingStart: SpaceBranding?
    /// The look Undo put back, which is not itself a change to remember.
    private var restoredLook: SpaceBranding?

    var canUndo: Bool { !looks.isEmpty }

    // MARK: - Mutators

    /// Remembers the look a change replaced, unless a drag is still running
    /// or the change is Undo putting a look back.
    mutating func noteChange(from previous: SpaceBranding, to current: SpaceBranding) {
        if let restored = restoredLook {
            restoredLook = nil
            if current == restored { return }
        }
        guard editingStart == nil else { return }
        remember(previous)
    }

    /// Marks a drag's start or end over `current`: one change to undo,
    /// however many samples the drag sent.
    mutating func setEditing(_ editing: Bool, over current: SpaceBranding) {
        if editing {
            if editingStart == nil { editingStart = current }
        } else if let start = editingStart {
            editingStart = nil
            if start != current { remember(start) }
        }
    }

    /// Takes the look to put back, if there is one.
    mutating func undo() -> SpaceBranding? {
        guard let previous = looks.popLast() else { return nil }
        restoredLook = previous
        return previous
    }

    private mutating func remember(_ previous: SpaceBranding) {
        looks.append(previous)
        if looks.count > Self.limit { looks.removeFirst() }
    }
}

/// A Space's appearance, in the order a person shapes it: its crest or icon
/// on the Space's own sidebar field, then its icon on its own, a crest in the
/// house's own colors or a plain symbol or emoji, which never changes the
/// Space's colors: those come from its theme, picked in the Theme row over
/// this page. More Customization is a page of its own that holds the rest,
/// under the stage again with a color for each part of the crest: the
/// sidebar's pattern and finish, and the parts of the crest. A theme, which
/// has no icon, shows its colors, presets or any color by hex code, under its
/// stage and all it carries at once.
struct BrowserCrestForge: View {
    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    /// The part of the crest More Customization shows.
    @Binding var step: BrowserCrestStudioStep
    /// The Space's name, for a page that doesn't already let a person edit it.
    var name: Binding<String>? = nil
    /// Whether More Customization lists the crest's parts, each opening on a
    /// page of its own, in place of the step bar: a phone has no room for six
    /// segments.
    var listsSteps = false
    /// Whether this is the whole page rather than one part's own page.
    var showsStepBar = true
    /// The Forge's history, on one of the step pages it opens; the Forge
    /// itself keeps its own.
    var sharedHistory: Binding<BrowserCrestForgeHistory>? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var initialAppearance: SpaceBranding?
    @State private var ownHistory = BrowserCrestForgeHistory()
    /// Whether the page shows More Customization in place of the Appearance
    /// page, as a page a person goes into and back out of.
    @State private var showsMore = false
    @Environment(\.browserSpaceThemeFiles) var themeFiles
    /// The theme the Forge edits in place of a Space, when it edits one.
    @Environment(\.browserThemeForgeSubject) var themeSubject
    /// Why the last theme file could not be written or read, until the next try.
    @State var themeFileProblem: String?

    private var history: Binding<BrowserCrestForgeHistory> { sharedHistory ?? $ownHistory }

    private var editingStart: SpaceBranding? { history.wrappedValue.editingStart }

    var context: BrowserCrestStudioContext {
        BrowserCrestStudioContext(
            branding: $branding,
            defaults: branding.startingLook ?? initialAppearance ?? branding,
            compact: false, previewBranding: editingStart)
    }

    private var isCrest: Bool { branding.iconStyle == .layeredCrest }

    var body: some View {
        BrowserSettingsPane(.spaces) {
            if !showsStepBar {
                stepSections
            } else if showsMore {
                morePage
            } else {
                page
            }
        }
        // Going into More Customization or back out starts at its top.
        .id(showsMore)
        #if os(iOS)
            .modifier(
                BrowserCrestForgeStepPages(isEnabled: listsSteps) { step in
                    BrowserCrestForge(
                        branding: $branding, symbol: $symbol, step: .constant(step), showsStepBar: false,
                        sharedHistory: history
                    )
                    .navigationTitle(Text(step.title))
                    .navigationBarTitleDisplayMode(.inline)
                })
        #endif
        #if os(macOS)
            .environment(\.browserSettingsColumnWidth, BrowserCrestForgeMetrics.columnWidth)
        #endif
        .environment(
            \.crestStudioEditingChanged,
            BrowserCrestStudioEditingAction { editing in
                // A drag is one change to undo, and the galleries keep their
                // compositions while it runs.
                history.wrappedValue.setEditing(editing, over: branding)
            }
        )
        .onAppear { if initialAppearance == nil { initialAppearance = branding } }
        .onChange(of: branding) { previous, current in
            // The Forge sees its step pages' changes through the shared
            // binding, so it alone remembers them.
            guard sharedHistory == nil else { return }
            history.wrappedValue.noteChange(from: previous, to: current)
        }
        .accessibilityIdentifier("space-customization-controls")
    }

    // MARK: - Page

    /// The page: a Space's icon under its stage, and More Customization; a
    /// theme, which has no icon, shows its colors under its stage and what
    /// it carries at once. A Space takes its colors from its theme, so the
    /// colors and presets are themes in the Theme row, not rows of their own
    /// here.
    @ViewBuilder private var page: some View {
        if offersIcon {
            Section {
                BrowserSpaceIconPicker(branding: $branding, symbol: $symbol)
            } header: {
                VStack(alignment: .leading, spacing: BrowserCrestForgeMetrics.stageHeadingSpacing) {
                    stageHeader
                    CrestSettingsSectionHeading(title: "Icon")
                }
                .textCase(nil)
            }
            Section {
                Button {
                    withAnimation(CrestMotion.surface.unlessReducingMotion(reduceMotion)) { showsMore = true }
                } label: {
                    HStack(spacing: CrestSpacing.small) {
                        Text("More Customization")
                        Spacer(minLength: CrestSpacing.small)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("more-customization")
            }
        } else {
            Section {
                BrowserSpaceColorWells(branding: $branding)
                BrowserSpacePalettePicker(branding: $branding)
            } header: {
                VStack(alignment: .leading, spacing: BrowserCrestForgeMetrics.stageHeadingSpacing) {
                    stageHeader
                    CrestSettingsSectionHeading(title: "Colors")
                }
                .textCase(nil)
            }
            Section {
                sidebarPatterns
            } header: {
                CrestSettingsSectionHeading(title: "Sidebar")
            }
            sidebarSettings
            otherSections
        }
    }

    /// More Customization: the way back to the Appearance page, the stage
    /// again with a color for each part of the crest, then the sidebar, the
    /// crest's parts and what the Space dresses beyond them.
    @ViewBuilder private var morePage: some View {
        Section {
            sidebarPatterns
        } header: {
            VStack(alignment: .leading, spacing: BrowserCrestForgeMetrics.stageHeadingSpacing) {
                moreHeading
                stageHeader
                CrestSettingsSectionHeading(title: "Sidebar")
            }
            .textCase(nil)
        }
        sidebarSettings
        if isCrest {
            crestSections
        }
        otherSections
    }

    /// More Customization's name, after the way back to the Appearance page.
    private var moreHeading: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(CrestMotion.surface.unlessReducingMotion(reduceMotion)) { showsMore = false }
            } label: {
                Label("Appearance", systemImage: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(CrestChromeButtonStyle())
            .labelStyle(.iconOnly)
            .help(Text("Appearance"))
            .accessibilityLabel(Text("Back to Appearance"))
            .accessibilityIdentifier("more-customization-back")
            Text("More Customization")
                .font(CrestTypography.display(20))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The stage heads the page's first section, outside the grouped boxes,
    /// so the crest sits on the Space's field alone.
    var stageHeader: some View {
        BrowserCrestForgeStage(
            branding: $branding, symbol: symbol, showsCrestColors: offersIcon && (showsMore || !showsStepBar),
            name: name, canUndo: history.wrappedValue.canUndo, shuffle: shuffle, undo: undo,
            openStep: { opened in
                step = opened
                showsMore = true
            }
        )
        .textCase(nil)
        .padding(.bottom, CrestSpacing.extraSmall)
    }

    // MARK: - Sidebar

    private var sidebarPatterns: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: CrestSpacing.small)], spacing: CrestSpacing.small
        ) {
            ForEach(SpaceBannerPattern.all, id: \.self) { pattern in
                patternChoice(pattern)
            }
        }
        .padding(.vertical, CrestSpacing.extraSmall)
        .accessibilityIdentifier("space-sidebar-patterns")
    }

    @ViewBuilder private var sidebarSettings: some View {
        Section {
            BrowserCrestStudioSlider(title: "Intensity", value: context.setting(\.bannerStrength))
            BrowserCrestStudioSlider(title: "Readability fade", value: context.setting(\.readabilityFade))
            BrowserCrestStudioSlider(title: "Folder colors", value: context.setting(\.folderColorIntensity))
            BrowserCrestStudioSlider(
                title: "Texture", value: context.setting(\.textureStrength),
                readout: .percent(zero: "None", full: "Full"))
            textColor
            BrowserCrestStudioSidebarTextColors(context: context)
        }
        BrowserCrestForgeThemeSidebarSections(context: context)
    }

    private func patternChoice(_ pattern: SpaceBannerPattern) -> some View {
        let isWorn =
            branding.themeMode == .gradient
            ? pattern == .solid : branding.bannerPattern == pattern
        return BrowserCrestStudioChoice(title: pattern.title, selected: isWorn) {
            context.branding.editorUpdate { $0.wearPattern(pattern) }
        } artwork: {
            BrowserSpaceBannerBackground(branding: context.preview { $0.wearPattern(pattern) })
                .frame(width: 56, height: 48)
                .clipShape(.rect(cornerRadius: CrestRadius.compact))
        }
    }

    private var textColor: some View {
        let text = context.setting(\.textColorMode)
        return CrestSettingRow("Text", setting: text.resettable("Text")) {
            Picker("Text", selection: text.binding) {
                ForEach(SpaceTextColorMode.all, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            #if os(macOS)
                .fixedSize()
            #endif
        }
    }

    // MARK: - Crest

    @ViewBuilder private var crestSections: some View {
        if listsSteps {
            Section {
                ForEach(BrowserCrestStudioStep.all) { step in
                    NavigationLink(value: step) {
                        LabeledContent {
                            Text(step.summary(branding))
                        } label: {
                            Label {
                                Text(step.title)
                            } icon: {
                                Image(systemName: step.symbol)
                            }
                        }
                    }
                    .accessibilityIdentifier("space-forge-step-\(step.name)")
                }
                spaceColorsRow
            } header: {
                CrestSettingsSectionHeading(title: "Crest")
            }
        } else {
            stepSections
            Section { spaceColorsRow }
        }
    }

    /// Gives a crest with colors of its own the Space's back.
    @ViewBuilder private var spaceColorsRow: some View {
        if !branding.crestFollowsSpace {
            LabeledContent("The crest has colors of its own.") {
                Button("Use Space Colors") {
                    context.branding.editorUpdate { $0.followSpaceColors() }
                }
            }
        }
    }

    /// The part of the crest chosen, under the crest's heading and step bar,
    /// or on its own page under the stage.
    @ViewBuilder private var stepSections: some View {
        switch step.kind {
        case .shape:
            crestGallery(\.backplate, CrestBackplate.offered)
        case .field:
            crestGallery(\.fieldDivision, CrestFieldDivision.offered)
        case .band:
            crestGallery(\.ordinary, CrestOrdinary.offered)
        case .emblem:
            Section {
                BrowserCrestStudioEmblem(context: context, symbol: symbol)
            } header: {
                stepHeader
            }
        case .border:
            crestGallery(\.trim, CrestTrim.offered)
        case .finish:
            finishGallery
        }
    }

    private var stepHeader: some View {
        Group {
            if showsStepBar {
                VStack(alignment: .leading, spacing: 10) {
                    CrestSettingsSectionHeading(title: "Crest")
                    BrowserPlatformCrestForgeStepBar(step: $step, disabledSteps: [])
                }
            } else {
                stageHeader
            }
        }
        .textCase(nil)
    }

    private var finishGallery: some View {
        gallery(BrowserCrestFinishChoice.all, id: \.self) { choice in
            BrowserCrestStudioChoice(title: choice.title, selected: choice.isWorn(by: branding.crest)) {
                context.branding.editorUpdate {
                    $0.crest = choice.applying(to: $0.crest)
                    $0.hasCustomAppearance = true
                }
            } artwork: {
                crest(context.preview { $0.crest = choice.applying(to: $0.crest) })
            }
        }
    }

    private func crestGallery<Option: Hashable & BrowserSpaceHeraldicTerm>(
        _ path: WritableKeyPath<SpaceCrest, Option>, _ offered: [Option]
    ) -> some View {
        let value = context.crest(path)
        // A crest wearing a part no longer offered keeps it among the choices.
        let options = offered.contains(value.wrappedValue) ? offered : offered + [value.wrappedValue]
        return gallery(options, id: \.self) { option in
            BrowserCrestStudioChoice(title: option.title, selected: option == value.wrappedValue) {
                value.binding.wrappedValue = option
            } artwork: {
                crest(context.preview { $0.crest[keyPath: path] = option })
            }
        }
    }

    private func gallery<Item, ID: Hashable, Tile: View>(
        _ items: [Item], id: KeyPath<Item, ID>, @ViewBuilder tile: @escaping (Item) -> Tile
    ) -> some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 80), spacing: CrestSpacing.small)], spacing: CrestSpacing.small
            ) {
                ForEach(items, id: id) { item in tile(item) }
            }
            .padding(.vertical, CrestSpacing.extraSmall)
            .accessibilityIdentifier("space-forge-gallery")
        } header: {
            stepHeader
        }
    }

    private func crest(_ look: SpaceBranding) -> some View {
        BrowserSpaceCrestIcon(branding: look, size: BrowserCrestForgeMetrics.tileCrestSize, rasterizesLayers: false)
            .equatable()
    }

    // MARK: - History

    private func undo() {
        guard let previous = history.wrappedValue.undo() else { return }
        branding = previous
    }

    private func shuffle() {
        branding = shuffledInOffer()
    }

    // MARK: - Looks

    /// A new crest and colors, every part chosen afresh from the ones More
    /// Customization offers: a dark tincture for the Background, a light one
    /// for the Accent, sometimes running on into the colors the harmony adds,
    /// and the crest in the Space's colors.
    static func shuffled(_ branding: SpaceBranding) -> SpaceBranding {
        let tinctures = Tincture.all.map(\.color)
        guard let dark = tinctures.filter({ $0.luminance < 0.3 }).randomElement(),
            let light = tinctures.filter({ $0.luminance > 0.42 }).randomElement()
        else { return branding }
        let chance = { (odds: Double) in Double.random(in: 0..<1) < odds }
        let run = { (color: BrandColor) in
            chance(0.5)
                ? CrestColorFill(
                    [color, CrestColorHarmony.run(beside: color)[0]], degrees: Double(Int.random(in: 0..<8) * 45))
                : CrestColorFill(color)
        }

        var look = branding
        look.iconStyle = .layeredCrest
        var crest = look.crest
        crest.backplate = CrestBackplate.offered.randomElement() ?? .shield
        crest.fieldDivision = chance(0.5) ? .plain : CrestFieldDivision.offered.filter { $0 != .plain }.randomElement()!
        crest.ordinary = chance(0.5) ? .none : CrestOrdinary.offered.filter { $0 != .none }.randomElement()!
        crest.symbol = CrestSymbol.selectable.randomElement() ?? .dragon
        crest.charge = nil
        crest.chargeLayout = chance(0.75) ? .single : [.paired, .trio].randomElement()!
        crest.trim = CrestTrim.offered.randomElement() ?? .none
        crest = (BrowserCrestFinishChoice.all.randomElement() ?? .shadow).applying(to: crest)
        look.crest = crest
        look.followSpaceColors()
        look.wearPattern(.solid)
        look.backgroundFill = run(dark)
        look.accentFill = run(light)
        look.hasCustomAppearance = true
        return look.normalized()
    }
}

#if os(iOS)
    /// Opens a listed part on a page of its own, where More Customization
    /// lists the crest's parts.
    private struct BrowserCrestForgeStepPages<Page: View>: ViewModifier {
        let isEnabled: Bool
        @ViewBuilder let page: (BrowserCrestStudioStep) -> Page

        func body(content: Content) -> some View {
            if isEnabled {
                content.navigationDestination(for: BrowserCrestStudioStep.self, destination: page)
            } else {
                content
            }
        }
    }
#endif
