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
    /// Arma has no forum: feedback goes to its GitHub Issues.
    static var feedback: URL {
        url("https://github.com/devops-senpai/Arma/issues")
    }

    static var issues: URL {
        url("https://github.com/devops-senpai/Arma/issues/new/choose")
    }

    /// Arma has no roadmap board: its open issues stand in.
    static var roadmap: URL {
        url("https://github.com/devops-senpai/Arma/issues")
    }

    private static func url(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid About link: \(value)")
        }
        return url
    }
}
