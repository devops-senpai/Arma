import Foundation

extension PasswordGeneration {
    // MARK: - Variables

    /// Where a person's choice starts: the default length from every group.
    static let seeded = PasswordGeneration(
        length: defaultLength, lowercase: true, uppercase: true, numbers: true, symbols: true)
}
