import SwiftUI

/// SwiftUI's `Glass` needs macOS 26. In the Mac targets this type takes its
/// name, so the shared views keep writing `.glassEffect(.regular, in: shape)`:
/// on macOS 26 it becomes the system's glass, and on macOS 15 a material in
/// the same shape.
struct Glass {
    // MARK: - Static Variables

    static var regular: Glass { Glass() }

    // MARK: - Variables

    private var tintColor: Color?
    private var isInteractive = false

    // MARK: - Actions - Variants

    func tint(_ color: Color?) -> Glass {
        var glass = self
        glass.tintColor = color
        return glass
    }

    func interactive(_ isEnabled: Bool = true) -> Glass {
        var glass = self
        glass.isInteractive = isEnabled
        return glass
    }

    // MARK: - Actions - Drawing

    @available(macOS 26.0, *)
    fileprivate var system: SwiftUI.Glass {
        SwiftUI.Glass.regular.tint(tintColor).interactive(isInteractive)
    }

    /// What macOS 15 draws in the glass's place: a material, under the tint
    /// when the glass has one.
    @ViewBuilder
    fileprivate func fallback(in shape: some Shape) -> some View {
        shape.fill(.regularMaterial)
        if let tintColor {
            shape.fill(tintColor)
        }
    }
}

extension View {
    @ViewBuilder
    func glassEffect(_ glass: Glass = .regular, in shape: some Shape = Capsule()) -> some View {
        if #available(macOS 26.0, *) {
            // The argument's type picks SwiftUI's modifier over this one.
            glassEffect(glass.system, in: shape)
        } else {
            background { glass.fallback(in: shape) }
        }
    }
}
