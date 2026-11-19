import Foundation

extension BrowserAboutReleaseNotes {
    /// The ids of the `entries` object in the order the catalog text lists them.
    ///
    /// `JSONDecoder` returns the entries as a dictionary and forgets that order, so
    /// one pass over the text recovers it: it tracks strings and nesting, and
    /// records each key one level inside the root `entries` object.
    static func entryOrder(in data: Data) -> [String] {
        let quote = UInt8(ascii: "\"")
        let escape = UInt8(ascii: "\\")
        let open = UInt8(ascii: "{")
        let close = UInt8(ascii: "}")
        let colon = UInt8(ascii: ":")
        let whitespace: Set<UInt8> = [UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\r"), UInt8(ascii: "\t")]
        var keys: [String] = []
        var depth = 0
        var entriesDepth: Int?
        var awaitingEntriesObject = false
        var index = data.startIndex
        while index < data.endIndex {
            let byte = data[index]
            index += 1
            switch byte {
            case open:
                depth += 1
                if awaitingEntriesObject {
                    entriesDepth = depth
                    awaitingEntriesObject = false
                }
            case close:
                if depth == entriesDepth { return keys }
                depth -= 1
            case quote:
                let start = index
                while index < data.endIndex, data[index] != quote {
                    index += data[index] == escape ? 2 : 1
                }
                let end = min(index, data.endIndex)
                index = end + 1
                var next = index
                while next < data.endIndex, whitespace.contains(data[next]) { next += 1 }
                guard next < data.endIndex, data[next] == colon else { continue }
                let key = Self.stringValue(of: data[start..<end])
                if depth == entriesDepth {
                    keys.append(key)
                } else if depth == 1, key == "entries" {
                    awaitingEntriesObject = true
                }
            default:
                break
            }
        }
        return keys
    }

    /// The text a JSON string literal's contents spell.
    static func stringValue(of contents: Data) -> String {
        guard contents.contains(UInt8(ascii: "\\")) else {
            return String(decoding: contents, as: UTF8.self)
        }
        var literal = Data([UInt8(ascii: "\"")])
        literal.append(contents)
        literal.append(UInt8(ascii: "\""))
        return (try? JSONDecoder().decode(String.self, from: literal)) ?? String(decoding: contents, as: UTF8.self)
    }
}
