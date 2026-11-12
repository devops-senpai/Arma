import SwiftUI

/// The surface of every flyout Crest draws over its windows, such as Site
/// Controls, a color picker, a permission request or a password prompt: one
/// solid dark surface whose labels are read in that same appearance, so
/// neither the Space's ink, a scheme the presenting view forces, the window's
/// appearance nor the page behind the flyout can put light labels on a light
/// background.
///
/// The material is one of its own rather than the device's surface choice,
/// laid over the window's own background: that choice suits layers on the
/// sidebar, but even the thickest material lets a bright page show through a
/// flyout held over it, and the labels must read against the surface alone.
///
/// A presented flyout, such as a popover, gets its surface from its
/// presentation. A flyout laid over the page inside the window draws it in
/// its own shape, and leaves the window's appearance alone.
///
/// A Space's theme can fill the surface and color the labels with
/// ``CrestFlyoutColors``. A fill lays over the material, and a light one
/// reads its labels in the light appearance, so they stay dark on it.
struct CrestFlyoutStyle: ViewModifier {
    // MARK: - Static Variables

    private static let material = CrestSurfaceMaterial.thick

    // MARK: - Variables

    /// The shape an in-window flyout's surface fills, or nil for a presented
    /// flyout, whose presentation fills its own.
    let inWindowShape: AnyShape?

    @Environment(\.crestFlyoutColors) private var colors

    @ViewBuilder
    func body(content: Content) -> some View {
        let colorScheme = colors.colorScheme
        let labels =
            content
            .foregroundStyle(colors.text.map { AnyShapeStyle($0.color) } ?? AnyShapeStyle(.primary))
            .tint(CrestBrandTheme.accent(colorScheme))
            .environment(\.colorScheme, colorScheme)
        if let inWindowShape {
            labels.background { surface(in: inWindowShape) }
        } else {
            labels
                .presentationBackground { surface(in: Rectangle()) }
                .preferredColorScheme(colorScheme)
        }
    }

    // MARK: - Actions - Drawing

    private func surface(in shape: some Shape) -> some View {
        shape
            .fill(CrestColor.windowBackground)
            .overlay { shape.fill(Self.material.material) }
            .overlay {
                if let background = colors.background { shape.fill(background.color) }
            }
            .environment(\.colorScheme, colors.colorScheme)
    }
}

/// The colors a Space's theme gives the flyouts its window shows: a fill for
/// the surface and one color for the labels, each nil for the standard one.
struct CrestFlyoutColors: Equatable, Sendable {
    // MARK: - Static Variables

    /// About the fill and labels the standard surface shows, for a color
    /// well with nothing chosen.
    static let standardBackground = BrandColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
    static let standardText = BrandColor(red: 1, green: 1, blue: 1, alpha: 1)

    // MARK: - Variables

    var background: BrandColor?
    var text: BrandColor?

    /// The appearance the flyout reads in: light over a light fill, so the
    /// standard labels stay dark on it, and dark otherwise.
    var colorScheme: ColorScheme {
        guard let background, background.alpha > 0.5 else { return .dark }
        return background.luminance > 0.5 ? .light : .dark
    }
}

extension EnvironmentValues {
    /// The colors flyouts presented from here wear; standard by default.
    @Entry var crestFlyoutColors = CrestFlyoutColors()
}

extension View {
    /// Draws this presented flyout's content on Crest's flyout surface. A
    /// popover gets it from
    /// ``crestPopover(isPresented:attachmentAnchor:arrowEdge:content:)``.
    func crestFlyoutStyle() -> some View {
        modifier(CrestFlyoutStyle(inWindowShape: nil))
    }

    /// Draws this flyout, laid over the page inside the window, on Crest's
    /// flyout surface in `shape`. Apply it after an outline or divider the
    /// flyout draws, so they read in the surface's appearance too.
    func crestFlyoutStyle(in shape: some Shape) -> some View {
        modifier(CrestFlyoutStyle(inWindowShape: AnyShape(shape)))
    }
}

#if DEBUG
    #Preview("Flyout from a light Space") {
        VStack(alignment: .leading, spacing: CrestSpacing.medium) {
            Text(verbatim: "example.com").font(.headline)
            Text(verbatim: "Wants to use your camera").foregroundStyle(.secondary)
            HStack {
                Button("Deny") {}.buttonStyle(.bordered)
                Button("Allow") {}.buttonStyle(.borderedProminent)
            }
        }
        .padding(CrestSpacing.medium)
        .crestFlyoutStyle(in: .rect(cornerRadius: CrestRadius.compact))
        .foregroundStyle(Color.black)
        .environment(\.colorScheme, .light)
        .padding()
        .background(Color.white)
    }
#endif
