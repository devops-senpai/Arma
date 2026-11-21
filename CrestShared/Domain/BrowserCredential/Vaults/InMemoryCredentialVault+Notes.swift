import Foundation

extension InMemoryCredentialVault {
    func notes(for id: UUID, in spaceID: UUID) -> String? {
        notesBySpace[spaceID]?[id]
    }

    func setNotes(_ notes: String?, for id: UUID, isSynchronizable: Bool, in spaceID: UUID) {
        notesBySpace[spaceID, default: [:]][id] = notes?.isEmpty == false ? notes : nil
    }
}
