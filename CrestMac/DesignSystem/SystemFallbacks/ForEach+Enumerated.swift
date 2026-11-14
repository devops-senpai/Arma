import SwiftUI

extension ForEach where Content: View {
    /// `ForEach(items.enumerated(), id:)` relies on `EnumeratedSequence` being
    /// a `RandomAccessCollection`, which it is only from macOS 26. This takes
    /// the same call on macOS 15 and hands `ForEach` the pairs as an array.
    init<Base: RandomAccessCollection>(
        _ data: EnumeratedSequence<Base>,
        id: KeyPath<EnumeratedSequence<Base>.Element, ID>,
        @ViewBuilder content: @escaping (EnumeratedSequence<Base>.Element) -> Content
    ) where Data == [EnumeratedSequence<Base>.Element] {
        self.init(Array(data), id: id, content: content)
    }
}
