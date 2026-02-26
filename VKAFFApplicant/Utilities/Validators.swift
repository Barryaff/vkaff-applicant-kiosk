import Foundation

enum Validators {
    // MARK: - NRIC / FIN
    /// Validates Singapore NRIC/FIN: starts with S/T/F/G/M, 7 digits, ends with 1 letter
    static func isValidNRIC(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces).uppercased()
        let pattern = "^[STFGM]\\d{7}[A-Z]$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Email
    static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Phone (Singapore)
    static func isValidPhone(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        // Allow 8-digit Singapore numbers or with country code
        return digits.count >= 8 && digits.count <= 15
    }

    // MARK: - Postal Code (Singapore 6 digits)
    static func isValidPostalCode(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        return digits.count == 6
    }

    // MARK: - Non-empty
    static func isNotEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
