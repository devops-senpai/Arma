import Foundation

struct BrowserAboutBuildInformation: Equatable, Sendable {
    let version: String
    let build: String
    let bundleIdentifier: String

    static let current = BrowserAboutBuildInformation(bundle: .main)

    init(bundle: Bundle) {
        self.init(
            infoDictionary: bundle.infoDictionary ?? [:],
            bundleIdentifier: bundle.bundleIdentifier
        )
    }

    init(
        infoDictionary: [String: Any],
        bundleIdentifier: String?
    ) {
        version = infoDictionary["CFBundleShortVersionString"] as? String ?? "—"
        build = infoDictionary["CFBundleVersion"] as? String ?? "—"
        self.bundleIdentifier =
            bundleIdentifier ?? ProductIdentity.bundleIdentifier
    }
}

enum BrowserAboutLinks {
    static var feedback: URL {
        url("https://www.reddit.com/r/CrestBrowser")
    }

    static var issues: URL {
        url("https://github.com/pauljoda/Crest/issues/new/choose")
    }

    static var roadmap: URL {
        url("https://github.com/users/pauljoda/projects/3")
    }

    private static func url(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid About link: \(value)")
        }
        return url
    }
}

enum BrowserAboutReleaseNoteCategory: String, Decodable, Sendable {
    case new
    case improved
    case fixed
    case `internal`
}

struct BrowserAboutReleaseNote: Equatable, Identifiable, Sendable {
    let id: String
    let category: BrowserAboutReleaseNoteCategory
    let message: String
}

/// The release-note catalog Crest ships, in the order the catalog lists it.
///
/// The catalog only ever appends, so its order is its chronology: the last
/// entries are the newest. Entry ids are plain words, not dates, so sorting
/// them says nothing about age.
struct BrowserAboutReleaseNotes: Sendable {
    private struct Document: Decodable {
        let entries: [String: Entry]
    }

    private struct Entry: Decodable {
        let category: BrowserAboutReleaseNoteCategory
        let message: String
    }

    /// How many of the newest public entries What's New lists.
    static let highlightLimit = 12

    static let bundled = loadBundled()

    /// Every entry, oldest first.
    let entries: [BrowserAboutReleaseNote]

    /// The newest public entries, newest first, capped at `highlightLimit`.
    let currentHighlights: [BrowserAboutReleaseNote]

    init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)
        var remaining = document.entries
        var ordered = Self.entryOrder(in: data).compactMap { id in
            remaining.removeValue(forKey: id).map { entry in
                BrowserAboutReleaseNote(id: id, category: entry.category, message: entry.message)
            }
        }
        // Anything the scan missed still appears, after the ordered entries.
        for (id, entry) in remaining.sorted(by: { $0.key < $1.key }) {
            ordered.append(BrowserAboutReleaseNote(id: id, category: entry.category, message: entry.message))
        }
        self.init(entries: ordered)
    }

    init(entries: [BrowserAboutReleaseNote]) {
        self.entries = entries
        let publicEntries = entries.filter { $0.category != .internal }
        currentHighlights = publicEntries.suffix(Self.highlightLimit).reversed()
    }

    private static func loadBundled() -> BrowserAboutReleaseNotes {
        guard
            let url = Bundle.main.url(
                forResource: "ReleaseNotes",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let releaseNotes = try? BrowserAboutReleaseNotes(data: data)
        else {
            return BrowserAboutReleaseNotes(entries: [])
        }
        return releaseNotes
    }
}
