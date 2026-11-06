import Observation
import SwiftUI

/// A Space held over Settings' list of Spaces: lifted from one of the list's
/// rows, or dragged in from a group page's crests. It knows where each row
/// stands and where the pointer holds the Space, and so which row or gap the
/// pointer aims at.
@Observable @MainActor
final class BrowserSettingsSpaceDrag {
    // MARK: - Types

    /// Where the pointer holds a Space among the rows.
    struct Aim: Equatable {
        /// The row the pointer rests on, when it aims at the row itself
        /// rather than at the gap above or below it.
        let row: Int?
        /// The gap nearest the pointer, as the row that follows it; the count
        /// of rows for the gap after the last.
        let gap: Int
    }

    // MARK: - Static Variables

    /// The coordinate space the rows are measured in and the pointer is
    /// reported in.
    static let coordinateSpace = "settings-spaces"
    /// A press must travel this far before it lifts a row, so a click that
    /// slips still chooses the row.
    static let liftDistance: CGFloat = 4
    /// The share of a row's height, at its top and at its bottom, that aims
    /// at the gap beside the row rather than at the row.
    private static let edgeShare: CGFloat = 0.3
    /// How long after a lift ends a row ignores the click the same release
    /// may report.
    private static let activationSuppression: Duration = .milliseconds(250)

    // MARK: - Variables

    /// The Space a row drag lifted, while the pointer holds it.
    private(set) var liftedSpaceID: UUID?
    /// Where the pointer holds the dragged Space; nil while it is away from
    /// the list.
    private(set) var pointer: CGPoint?
    /// How far the pointer was from the lifted row's corner when it lifted.
    private var grip = CGSize.zero
    private var rowFrames: [UUID: CGRect] = [:]
    private var isSuppressingActivation = false
    /// The row a Space dragged in from a crest is over.
    @ObservationIgnored private var heldRowID: UUID?
    @ObservationIgnored private var activationSuppressionTask: Task<Void, Never>?

    /// Whether a row's click is the end of a lift rather than a choice.
    var suppressesActivation: Bool { liftedSpaceID != nil || isSuppressingActivation }

    /// Where the lifted row's corner is as it follows the pointer.
    var liftedOrigin: CGPoint? {
        guard liftedSpaceID != nil, let pointer else { return nil }
        return CGPoint(x: pointer.x - grip.width, y: pointer.y - grip.height)
    }

    // MARK: - Actions - Measuring

    /// Records where the row of `id` stands, or that it left when `frame` is
    /// nil.
    func place(row id: UUID, at frame: CGRect?) {
        guard rowFrames[id] != frame else { return }
        rowFrames[id] = frame
    }

    func frame(ofRow id: UUID) -> CGRect? {
        rowFrames[id]
    }

    // MARK: - Actions - Holding

    /// Lifts the row of `id`, pressed at `start`, to follow the pointer at
    /// `point`.
    func lift(_ id: UUID, from start: CGPoint, to point: CGPoint) {
        if liftedSpaceID != id, let frame = rowFrames[id] {
            grip = CGSize(width: start.x - frame.minX, height: start.y - frame.minY)
        }
        liftedSpaceID = id
        pointer = point
    }

    /// Holds a Space dragged in from elsewhere over the row of `id`, at
    /// `point` inside that row.
    func hold(overRow id: UUID, at point: CGPoint) {
        guard let frame = rowFrames[id] else { return }
        heldRowID = id
        pointer = CGPoint(x: frame.minX + point.x, y: frame.minY + point.y)
    }

    /// Takes a Space dragged in from elsewhere off the row of `id`, unless it
    /// has already moved onto another.
    func leave(row id: UUID) {
        guard heldRowID == id else { return }
        heldRowID = nil
        pointer = nil
    }

    /// Lets go of the Space. The click the release of a lift may report is
    /// ignored.
    func release() {
        if liftedSpaceID != nil { suppressActivation() }
        liftedSpaceID = nil
        heldRowID = nil
        pointer = nil
    }

    private func suppressActivation() {
        isSuppressingActivation = true
        activationSuppressionTask?.cancel()
        activationSuppressionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.activationSuppression)
            guard !Task.isCancelled else { return }
            self?.isSuppressingActivation = false
        }
    }

    // MARK: - Actions - Aiming

    /// Where the pointer holds the Space `id` among the rows of `ids`, in
    /// their order; nil while it is away from them or still over the Space's
    /// own row, so a drag that barely moved lands nowhere.
    func aim(holding id: UUID, among ids: [UUID]) -> Aim? {
        guard let pointer else { return nil }
        let frames = ids.compactMap { rowFrames[$0] }
        guard frames.count == ids.count, let first = frames.first, let last = frames.last,
            pointer.x >= first.minX, pointer.x <= first.maxX
        else { return nil }
        let reach = first.height / 2
        guard pointer.y >= first.minY - reach, pointer.y <= last.maxY + reach else { return nil }
        if pointer.y < first.minY { return Aim(row: nil, gap: 0) }
        guard let index = frames.firstIndex(where: { pointer.y < $0.maxY }) else {
            return Aim(row: nil, gap: ids.count)
        }
        guard ids[index] != id else { return nil }
        let frame = frames[index]
        let edge = frame.height * Self.edgeShare
        let restsOnRow = pointer.y >= frame.minY + edge && pointer.y <= frame.maxY - edge
        return Aim(row: restsOnRow ? index : nil, gap: pointer.y < frame.midY ? index : index + 1)
    }
}
