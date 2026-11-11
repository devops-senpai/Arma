import Foundation

/// Where the `arma` command this app carries can go on the person's PATH.
///
/// Arma never runs anything with raised privileges. It links the helper into
/// `~/.local/bin` or `~/bin`, the first that exists and is on the PATH, both
/// folders the person owns; anywhere else it offers the command to copy into
/// a terminal instead. The PATH is the person's login shell's, read once in
/// the background, since an app started from the Dock inherits a shorter one.
@MainActor
final class BrowserCommandLineInstall {
    // MARK: - Types

    /// What the person's PATH holds under the name `arma`.
    enum Presence: Equatable {
        /// Not found yet, or not there.
        case absent
        /// `url` is this app's helper, directly or through links.
        case installed(URL)
        /// `url` is some other program named `arma`.
        case other(URL)
    }

    // MARK: - Static Variables

    static let shared = BrowserCommandLineInstall()

    /// The folders Arma may link the command into, in the order it tries them.
    static let userFolders = ["~/.local/bin", "~/bin"]

    // MARK: - Variables

    /// The helper inside this app.
    let helper = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/arma", isDirectory: false)

    /// The login shell's PATH, or nil until it has been read.
    private(set) var searchPath: [String]?
    private var isReading = false

    /// Whether macOS runs this copy of Arma from a temporary place, whose
    /// path changes every launch, so a link to it would soon break.
    var isTranslocated: Bool { helper.path.contains("/AppTranslocation/") }

    /// The PATH to check: the login shell's once read, this process's before.
    private var path: [String] {
        searchPath ?? (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
    }

    /// What answers `arma` on the PATH.
    var presence: Presence {
        for folder in path {
            let candidate = URL(fileURLWithPath: Self.expanded(folder), isDirectory: true).appendingPathComponent(
                "arma")
            guard FileManager.default.fileExists(atPath: candidate.path) else { continue }
            let target = candidate.resolvingSymlinksInPath().standardizedFileURL
            return target == helper.resolvingSymlinksInPath().standardizedFileURL
                ? .installed(candidate) : .other(candidate)
        }
        return .absent
    }

    /// The first of ``userFolders`` that exists, is on the PATH and holds no
    /// `arma` yet, as the person writes it (`~/.local/bin`), or nil.
    var userFolder: String? {
        let onPath = Set(path.map { Self.expanded($0) })
        return Self.userFolders.first { folder in
            let expanded = Self.expanded(folder)
            var isFolder: ObjCBool = false
            return onPath.contains(expanded)
                && FileManager.default.fileExists(atPath: expanded, isDirectory: &isFolder) && isFolder.boolValue
                && !FileManager.default.fileExists(atPath: expanded + "/arma")
        }
    }

    /// The line that links the command into `folder`, quoted for a shell.
    func linkCommand(into folder: String) -> String {
        let target = folder.hasPrefix("~/") ? folder : "'\(folder)'"
        let link = "ln -s '\(helper.path)' \(target)/arma"
        return folder.hasPrefix("/usr/") ? "sudo \(link)" : link
    }

    /// The line that makes `~/.local/bin`, links the command there and puts
    /// the folder on zsh's PATH, for a person who has none of the folders.
    var setUpCommand: String {
        "mkdir -p ~/.local/bin && \(linkCommand(into: "~/.local/bin"))"
            + " && echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.zprofile"
    }

    // MARK: - Actions - Reading

    /// Reads the login shell's PATH once, in the background.
    func readSearchPath() {
        guard searchPath == nil, !isReading else { return }
        isReading = true
        Task.detached(priority: .utility) {
            let read = Self.loginShellPath()
            await MainActor.run {
                self.searchPath = read ?? self.path
                self.isReading = false
            }
        }
    }

    /// The PATH an interactive login shell sets up, which is where `~/.local/bin`
    /// usually joins it, or nil when the shell does not answer in three seconds.
    private nonisolated static func loginShellPath() -> [String]? {
        let shell = ProcessInfo.processInfo.environment["SHELL"].flatMap { $0.isEmpty ? nil : $0 } ?? "/bin/zsh"
        let marker = "__ARMA_PATH__"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-i", "-c", "printf '\(marker)%s' \"$PATH\""]
        process.standardInput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        let output = Pipe()
        process.standardOutput = output
        do { try process.run() } catch { return nil }
        let deadline = Date().addingTimeInterval(3)
        while process.isRunning, Date() < deadline { usleep(50_000) }
        if process.isRunning {
            process.terminate()
            return nil
        }
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard let range = text.range(of: marker, options: .backwards) else { return nil }
        return text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":").map(String.init)
    }

    // MARK: - Actions - Installing

    /// Links the command into `folder`, one of ``userFolders``, answering the
    /// link, or nil when it could not be made.
    func install(into folder: String) -> URL? {
        guard Self.userFolders.contains(folder), !isTranslocated else { return nil }
        let link = URL(fileURLWithPath: Self.expanded(folder), isDirectory: true).appendingPathComponent("arma")
        do {
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: helper)
            return link
        } catch {
            return nil
        }
    }

    /// `path` with a leading `~` spelled out.
    static func expanded(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    /// `url` with the home folder written as `~`.
    static func abbreviated(_ url: URL) -> String {
        (url.path as NSString).abbreviatingWithTildeInPath
    }
}
