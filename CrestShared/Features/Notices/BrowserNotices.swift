import Observation

/// The notice a window shows at its top. A newer notice replaces one still
/// showing, and each leaves once it has been up as long as it lasts. Every
/// layer that draws the window's notices reads the one showing here, so a
/// sheet that opens over the window shows it too, and none shows it again
/// after it left.
///
/// A notice that offers an action stays while the pointer rests on it, and
/// leaves `graceAfterHover` after the pointer does, so a person reaching for
/// the action never loses it on the way. Taking the action puts it away.
@Observable
@MainActor
final class BrowserNotices {
    // MARK: - Static Variables

    /// How long a notice stays once the pointer leaves it.
    static let graceAfterHover: Duration = .milliseconds(1_500)

    // MARK: - Variables

    /// The notice showing now, or nil while none shows.
    private(set) var shown: BrowserNotice? {
        get { observed(\.shownStorage, as: \.shown) }
        set { publish(newValue, into: \.shownStorage, as: \.shown) }
    }
    @ObservationIgnored private var shownStorage: BrowserNotice?
    /// Counts each time the notice's leaving is set or called off, so only
    /// the latest timer puts a notice away.
    @ObservationIgnored private var revision = 0
    /// Whether the pointer rests on the notice, which holds it up.
    @ObservationIgnored private(set) var isHovered = false

    // MARK: - Actions - Showing

    /// Shows `notice`, replacing any notice already showing, for as long as
    /// it lasts.
    func show(_ notice: BrowserNotice) {
        isHovered = false
        shown = notice
        leave(after: notice.duration)
    }

    /// Follows the pointer resting on a notice that offers an action: while
    /// it does the notice stays, and once it leaves the notice goes after
    /// `graceAfterHover`. A notice without an action keeps its own time.
    func hoverChanged(_ hovering: Bool) {
        guard shown?.action != nil, hovering != isHovered else { return }
        isHovered = hovering
        if hovering {
            revision &+= 1
        } else {
            leave(after: Self.graceAfterHover)
        }
    }

    /// Takes the action the notice offers, and puts the notice away.
    func performAction() {
        guard let action = shown?.action else { return }
        dismiss()
        action.perform()
    }

    /// Puts the notice away now.
    func dismiss() {
        revision &+= 1
        isHovered = false
        shown = nil
    }

    private func leave(after duration: Duration) {
        revision &+= 1
        let shownRevision = revision
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self, revision == shownRevision else { return }
            isHovered = false
            shown = nil
        }
    }
}

extension BrowserNotices: BrowserStoreFirstObservable {}
