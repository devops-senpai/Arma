import SwiftUI

/// SwiftUI's glass button styles need macOS 26. This style takes their names
/// in the Mac targets, so `.buttonStyle(.glass)` and `.glassProminent` draw
/// the system's glass buttons on macOS 26 and its bordered ones on macOS 15.
struct GlassButtonStyle: PrimitiveButtonStyle {
    // MARK: - Variables

    private var isProminent = false

    // MARK: - Initializers

    init(_ glass: Glass = .regular) {}

    fileprivate init(isProminent: Bool) {
        self.isProminent = isProminent
    }

    // MARK: - Actions - Drawing

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26.0, *) {
            if isProminent {
                Button(configuration).buttonStyle(SwiftUI.GlassProminentButtonStyle())
            } else {
                Button(configuration).buttonStyle(SwiftUI.GlassButtonStyle())
            }
        } else {
            if isProminent {
                Button(configuration).buttonStyle(.borderedProminent)
            } else {
                Button(configuration).buttonStyle(.bordered)
            }
        }
    }
}

extension PrimitiveButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
    static var glassProminent: GlassButtonStyle { GlassButtonStyle(isProminent: true) }
}
