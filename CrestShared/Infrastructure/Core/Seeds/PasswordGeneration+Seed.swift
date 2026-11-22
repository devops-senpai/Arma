import Foundation

extension PasswordGeneration {
    // MARK: - Static Variables

    /// The strong password recipe's default: its default length, from every
    /// group.
    static let standard = PasswordGeneration(
        length: defaultLength, lowercase: true, uppercase: true, numbers: true, symbols: true)
}
