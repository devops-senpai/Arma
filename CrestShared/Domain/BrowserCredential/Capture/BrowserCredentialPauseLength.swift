import Foundation

/// How long Arma's password prompts stay paused on a tab: until the person
/// resumes them, or for a set time after which they come back on their own.
/// Either way the person can resume them sooner.
struct BrowserCredentialPauseLength: Hashable, Identifiable, Sendable {
    // MARK: - Static Variables

    static let untilResumed = BrowserCredentialPauseLength(
        id: "until-resumed", seconds: nil, title: String(localized: "Until Resumed"))
    static let oneMinute = BrowserCredentialPauseLength(
        id: "1m", seconds: 60, title: String(localized: "For 1 Minute"))
    static let twoMinutes = BrowserCredentialPauseLength(
        id: "2m", seconds: 2 * 60, title: String(localized: "For 2 Minutes"))
    static let fiveMinutes = BrowserCredentialPauseLength(
        id: "5m", seconds: 5 * 60, title: String(localized: "For 5 Minutes"))
    static let tenMinutes = BrowserCredentialPauseLength(
        id: "10m", seconds: 10 * 60, title: String(localized: "For 10 Minutes"))
    static let thirtyMinutes = BrowserCredentialPauseLength(
        id: "30m", seconds: 30 * 60, title: String(localized: "For 30 Minutes"))
    static let oneHour = BrowserCredentialPauseLength(
        id: "1h", seconds: 60 * 60, title: String(localized: "For 1 Hour"))
    static let oneDay = BrowserCredentialPauseLength(
        id: "24h", seconds: 24 * 60 * 60, title: String(localized: "For 24 Hours"))

    static let all = [untilResumed, oneMinute, twoMinutes, fiveMinutes, tenMinutes, thirtyMinutes, oneHour, oneDay]

    // MARK: - Variables

    let id: String
    /// How long the pause lasts, or nil for one that lasts until resumed.
    let seconds: TimeInterval?
    let title: String

    /// The symbol a menu shows beside it.
    var systemImage: String { seconds == nil ? "pause.circle" : "timer" }

    // MARK: - Actions - Ending

    /// When a pause of this length started at `now` ends, or nil for one
    /// that lasts until resumed.
    func end(from now: Date) -> Date? {
        seconds.map { now.addingTimeInterval($0) }
    }
}
