import Foundation

/// A saved password's account, without the password: where it was saved, the
/// username and email it signs in with, the category it is filed under,
/// whether it also fills the hosts under its origin (`includesSubdomains`),
/// and when it was saved and used. Its notes are kept apart, as secret as the
/// password.
struct CredentialDescriptor: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let spaceID: UUID
    let origin: CredentialOrigin
    var scope: BrowserCredentialScope
    var username: String
    var displayName: String?
    var email: String?
    var category: String?
    var includesSubdomains: Bool
    let createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var isSynchronizable: Bool

    init(
        id: UUID = UUID(),
        spaceID: UUID,
        origin: CredentialOrigin,
        scope: BrowserCredentialScope = .webForm,
        username: String,
        displayName: String? = nil,
        email: String? = nil,
        category: String? = nil,
        includesSubdomains: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        lastUsedAt: Date? = nil,
        isSynchronizable: Bool = false
    ) {
        self.id = id
        self.spaceID = spaceID
        self.origin = origin
        self.scope = scope
        self.username = username
        self.displayName = displayName
        self.email = email
        self.category = category
        self.includesSubdomains = includesSubdomains
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.lastUsedAt = lastUsedAt
        self.isSynchronizable = isSynchronizable
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case spaceID
        case origin
        case scope
        case username
        case displayName
        case email
        case category
        case includesSubdomains
        case createdAt
        case updatedAt
        case lastUsedAt
        case isSynchronizable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIdentity(forKey: .id)
        spaceID = try container.decodeIdentity(forKey: .spaceID)
        origin = try container.decode(CredentialOrigin.self, forKey: .origin)
        scope =
            try container.decodeIfPresent(BrowserCredentialScope.self, forKey: .scope)
            ?? .webForm
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        includesSubdomains = try container.decodeIfPresent(Bool.self, forKey: .includesSubdomains) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        isSynchronizable = try container.decode(Bool.self, forKey: .isSynchronizable)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Descriptors keep the identity spelling every earlier build wrote.
        try container.encodeStoredIdentity(id, forKey: .id)
        // Synchronizable descriptors reach older builds on other devices,
        // which read only the stored spelling, so it stays for good.
        try container.encodeStoredIdentity(spaceID, forKey: .spaceID)
        try container.encode(origin, forKey: .origin)
        try container.encode(scope, forKey: .scope)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        // An older build reads neither, and a password that reaches no
        // subdomains is stored exactly as it stored one.
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(category, forKey: .category)
        if includesSubdomains { try container.encode(includesSubdomains, forKey: .includesSubdomains) }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
        try container.encode(isSynchronizable, forKey: .isSynchronizable)
    }
}
