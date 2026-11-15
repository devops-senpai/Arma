import SwiftUI

/// A flyout's plain button once its Space's theme gives buttons a fill or an
/// outline: a capsule in those colors with its label in the accent. A
/// disabled button keeps its capsule and reads its label in the secondary
/// text color, rather than fading the whole button as the system does, so it
/// stays legible on any fill.
struct CrestFlyoutButtonStyle: ButtonStyle {
    // MARK: - Variables

    let colors: CrestFlyoutColors

    // MARK: - Actions - Drawing

    func makeBody(configuration: Configuration) -> some View {
        Surface(colors: colors, configuration: configuration)
    }

    private struct Surface: View {
        let colors: CrestFlyoutColors
        let configuration: Configuration

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .font(.body.weight(.medium))
                .foregroundStyle(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .padding(.horizontal, CrestButtonMetrics.standardHorizontalPadding)
                .frame(minHeight: CrestButtonMetrics.standardHeight)
                .background {
                    if let button = colors.button {
                        Capsule().fill(
                            button.color.opacity(isEnabled && (isHovering || configuration.isPressed) ? 0.8 : 1))
                    }
                }
                .overlay {
                    if let outline = colors.buttonOutline {
                        Capsule().strokeBorder(outline.color, lineWidth: CrestButtonMetrics.strokeWidth)
                    }
                }
                .crestCapsuleInteractionShape()
                .scaleEffect(
                    (configuration.isPressed ? CrestButtonMetrics.pressedScale : 1).unlessReducingMotion(reduceMotion)
                )
                .animation(CrestMotion.press.unlessReducingMotion(reduceMotion), value: configuration.isPressed)
                .onHover { isHovering = $0 && isEnabled }
        }
    }
}
