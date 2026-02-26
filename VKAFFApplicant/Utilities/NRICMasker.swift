import Foundation

enum NRICMasker {
    /// Masks NRIC for display: S1234567A → S••••567A
    static func mask(_ nric: String) -> String {
        let trimmed = nric.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count == 9 else { return trimmed }

        let prefix = String(trimmed.prefix(1))       // S
        let lastFour = String(trimmed.suffix(4))       // 567A
        return "\(prefix)••••\(lastFour)"
    }

    /// Returns the full unmasked value
    static func unmask(_ stored: String) -> String {
        stored
    }
}
