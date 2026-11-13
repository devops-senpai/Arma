import SwiftUI

/// The stage's backdrop, the same behind every step: Catppuccin Macchiato's
/// base darkening to its mantle, soft mauve, blue and pink glows, and fine
/// lavender diagonals, as Arma's README art draws them. A chosen theme shows
/// in the page's previews rather than here.
struct BrowserOnboardingArmaBackdrop: View {
    // MARK: - Types

    /// A soft light: where it sits as a fraction of the stage, how far it
    /// reaches as a fraction of the stage's longer side, and its color.
    private struct Glow {
        let x: CGFloat
        let y: CGFloat
        let reach: CGFloat
        let color: Color
    }

    // MARK: - Static Variables

    private static let base = color(0x24273A)
    private static let mantle = color(0x1E2030)
    private static let lavender = color(0xB7BDF8)
    private static let glows = [
        Glow(x: 0.2, y: 0.28, reach: 0.5, color: color(0xC6A0F6)),
        Glow(x: 0.85, y: 0.78, reach: 0.55, color: color(0x8AADF4)),
        Glow(x: 0.55, y: 0.02, reach: 0.36, color: color(0xF5BDE6)),
    ]
    /// How strongly each glow lights its middle.
    private static let glowStrength = 0.3
    /// The gap between the diagonals, and how faintly they show.
    private static let lineSpacing: CGFloat = 22
    private static let lineOpacity = 0.06

    // MARK: - Actions - Drawing

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(
                Path(bounds),
                with: .linearGradient(
                    Gradient(colors: [Self.base, Self.mantle]), startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)))
            let longer = max(size.width, size.height)
            for glow in Self.glows {
                let center = CGPoint(x: size.width * glow.x, y: size.height * glow.y)
                context.fill(
                    Path(bounds),
                    with: .radialGradient(
                        Gradient(colors: [glow.color.opacity(Self.glowStrength), glow.color.opacity(0)]),
                        center: center, startRadius: 0, endRadius: longer * glow.reach))
            }
            var lines = Path()
            var x = -size.height
            while x < size.width {
                lines.move(to: CGPoint(x: x, y: size.height))
                lines.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += Self.lineSpacing
            }
            context.stroke(lines, with: .color(Self.lavender.opacity(Self.lineOpacity)), lineWidth: 1)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private static func color(_ hex: Int) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}
