import Foundation

enum CredentialKeychainNamespace {
    static let productionPrefix = ProductIdentity.serviceNamespace

    static func service(
        for spaceID: UUID,
        prefix: String = productionPrefix
    ) -> String {
        "\(prefix).space.\(spaceID.uuidString.lowercased()).credential"
    }

    /// Where a Space keeps the notes of its passwords, one item per password
    /// under the password's account. Apart from the passwords, so a build
    /// before notes reads every password as it did.
    static func noteService(
        for spaceID: UUID,
        prefix: String = productionPrefix
    ) -> String {
        "\(prefix).space.\(spaceID.uuidString.lowercased()).credential-note"
    }
}
