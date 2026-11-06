import Foundation

/// A password stays only in process memory until the person accepts or dismisses
/// the native save/update prompt. This value is deliberately non-Codable and redacted.
struct BrowserCredentialSaveCandidate: Identifiable, Equatable, Sendable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    let id: UUID
    let origin: CredentialOrigin
    let topLevelOrigin: CredentialOrigin
    /// The account and password the form was submitted with, until the person
    /// corrects them in the save prompt.
    var username: String
    var password: String
    let passwordKind: CredentialPasswordKind
    let isCrossOriginFrame: Bool
    let submittedAt: Date
    /// Whether the saved password should also fill the hosts under its origin,
    /// as the person chooses in the save prompt.
    var includesSubdomains = false
    /// What the person adds in the save prompt before saving: the account's
    /// email, the category it is filed under, and notes kept as secret as the
    /// password.
    var email = ""
    var category: String?
    var notes = ""

    var description: String {
        "BrowserCredentialSaveCandidate(id: \(id), origin: \(origin), username: \(username), password: <redacted>, notes: <redacted>)"
    }

    var debugDescription: String { description }
}
