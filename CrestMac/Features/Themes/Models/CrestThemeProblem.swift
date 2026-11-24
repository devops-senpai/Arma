import Foundation

/// Why a theme could not dress a Space.
enum CrestThemeProblem: Error {
    case unknownStyle(String)
    case unknownPattern(String)
    case unknownTextColor(String)
    case badColor(String)
    /// A kept crest names a part no crest draws: the part, the word, and the words it takes.
    case unknownCrestPart(String, String, [String])

    /// What the person reads at the terminal.
    var message: String {
        switch self {
        case .unknownStyle(let style):
            "The style '\(style)' is not banner or gradient."
        case .unknownPattern(let pattern):
            "The pattern '\(pattern)' is not one Arma draws. Try \(SpaceBannerPattern.all.map(\.name).joined(separator: ", "))."
        case .unknownTextColor(let mode):
            "The text color '\(mode)' is not automatic, light, dark or system."
        case .badColor(let text):
            "'\(text)' is not a color. Colors are #RRGGBB or #RRGGBBAA, or the word default."
        case .unknownCrestPart(let part, let word, let words):
            "The crest's \(part) '\(word)' is not one Arma draws. Try \(words.joined(separator: ", "))."
        }
    }
}
