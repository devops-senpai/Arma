import SwiftUI

/// What the person is asked after closing a password prompt: whether to
/// pause Arma's password prompts on this tab, for a page where another
/// password manager should answer. It stays for six seconds, and while the
/// pointer rests on it.
struct BrowserCredentialPauseOffer: View {
    // MARK: - Static Variables

    private static let lifetime: Duration = .seconds(6)
    private static let width: CGFloat = 300

    // MARK: - Variables

    let offerID: UUID
    let pause: (BrowserCredentialPauseLength) -> Void
    let dismiss: () -> Void
    let metrics: BrowserCredentialPromptMetrics

    @State private var isPointerResting = false

    // MARK: - Actions - Drawing

    var body: some View {
        BrowserCredentialPromptSurface(
            accessibilityLabel: Text("Pause Arma passwords on this tab?"),
            accessibilityIdentifier: "crest-password-pause-offer",
            width: .fixed(Self.width),
            metrics: metrics
        ) {
            HStack(spacing: CrestSpacing.small) {
                Image(systemName: "key.slash")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Pause Arma passwords on this tab?")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: CrestSpacing.small)
                // Pause lasts until resumed; the menu picks a time instead.
                Menu {
                    Group {
                        ForEach(BrowserCredentialPauseLength.all) { length in
                            Button(length.title, systemImage: length.systemImage) { pause(length) }
                        }
                    }
                    .crestMenuActionLabelStyle()
                } label: {
                    Text("Pause")
                } primaryAction: {
                    pause(.untilResumed)
                }
                .menuStyle(.button)
                .buttonStyle(.borderedProminent)
                .fixedSize()
                .accessibilityLabel(Text("Pause on This Tab"))
                .accessibilityIdentifier("crest-password-pause-tab")
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(CrestChromeButtonStyle())
                .accessibilityLabel(Text("Close"))
            }
        }
        .onHover { isPointerResting = $0 }
        .task(id: Countdown(offerID: offerID, isPointerResting: isPointerResting)) {
            guard !isPointerResting else { return }
            try? await Task.sleep(for: Self.lifetime)
            guard !Task.isCancelled, !isPointerResting else { return }
            dismiss()
        }
    }

    /// What restarts the countdown: another offer, or the pointer arriving or
    /// leaving.
    private struct Countdown: Hashable {
        let offerID: UUID
        let isPointerResting: Bool
    }
}
