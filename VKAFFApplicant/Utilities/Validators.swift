import Foundation

enum Validators {
    // MARK: - NRIC / FIN

    /// Validates Singapore NRIC/FIN with full checksum verification.
    /// S/T series: citizens/PRs born before/after 2000
    /// F/G series: foreigners issued FIN before/after 2000
    /// M series: foreigners issued FIN from 2022 onwards
    static func isValidNRIC(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces).uppercased()

        // Basic format check: prefix letter + 7 digits + checksum letter
        let pattern = "^[STFGM]\\d{7}[A-Z]$"
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return false
        }

        let prefix = trimmed.first!
        let digits = trimmed.dropFirst().dropLast().map { Int(String($0))! }
        let checksumLetter = trimmed.last!

        // Weights for NRIC/FIN checksum: [2, 7, 6, 5, 4, 3, 2]
        let weights = [2, 7, 6, 5, 4, 3, 2]
        var weightedSum = 0
        for i in 0..<7 {
            weightedSum += digits[i] * weights[i]
        }

        // Offset for T/G series (born/issued from 2000 onwards)
        if prefix == "T" || prefix == "G" {
            weightedSum += 4
        } else if prefix == "M" {
            weightedSum += 3
        }

        let remainder = weightedSum % 11

        // Lookup tables for the checksum letter
        let stChecksumTable: [Character] = ["J", "Z", "I", "H", "G", "F", "E", "D", "C", "B", "A"]
        let fgChecksumTable: [Character] = ["X", "W", "U", "T", "R", "Q", "P", "N", "M", "L", "K"]
        let mChecksumTable: [Character]  = ["X", "W", "U", "T", "R", "Q", "P", "N", "M", "L", "K"]

        let expectedLetter: Character
        switch prefix {
        case "S", "T":
            expectedLetter = stChecksumTable[remainder]
        case "F", "G":
            expectedLetter = fgChecksumTable[remainder]
        case "M":
            expectedLetter = mChecksumTable[remainder]
        default:
            return false
        }

        return checksumLetter == expectedLetter
    }

    /// Validates NRIC format only (without checksum), for real-time feedback
    /// while the user is still typing.
    static func isValidNRICFormat(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces).uppercased()
        let pattern = "^[STFGM]\\d{7}[A-Z]$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Email

    /// Validates email with stricter rules:
    /// - No consecutive dots in local part
    /// - No trailing dot before @
    /// - No leading dot after @
    /// - Standard format requirements
    static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }

        // Must contain exactly one @
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }

        let localPart = String(parts[0])
        let domainPart = String(parts[1])

        // Local part checks
        guard !localPart.isEmpty else { return false }
        guard !localPart.contains("..") else { return false }   // No consecutive dots
        guard !localPart.hasPrefix(".") else { return false }    // No leading dot
        guard !localPart.hasSuffix(".") else { return false }    // No trailing dot before @

        // Domain part checks
        guard !domainPart.isEmpty else { return false }
        guard !domainPart.contains("..") else { return false }   // No consecutive dots in domain
        guard !domainPart.hasPrefix(".") else { return false }   // No leading dot in domain
        guard !domainPart.hasPrefix("-") else { return false }   // No leading hyphen in domain
        guard domainPart.contains(".") else { return false }     // Must have at least one dot

        // Overall regex validation
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Phone (Singapore)

    /// Validates Singapore phone numbers specifically:
    /// - 8 digits starting with 6, 8, or 9 (local format)
    /// - Or +65 / 65 prefix followed by 8 digits starting with 6, 8, or 9
    static func isValidPhone(_ value: String) -> Bool {
        let cleaned = value.filter { $0.isNumber || $0 == "+" }

        // Strip country code if present
        var digits: String
        if cleaned.hasPrefix("+65") {
            digits = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("65") && cleaned.count == 10 {
            digits = String(cleaned.dropFirst(2))
        } else {
            digits = cleaned.filter { $0.isNumber }
        }

        // Must be exactly 8 digits
        guard digits.count == 8 else { return false }

        // Must start with 6, 8, or 9 (Singapore mobile/landline)
        guard let firstDigit = digits.first,
              firstDigit == "6" || firstDigit == "8" || firstDigit == "9" else {
            return false
        }

        return true
    }

    // MARK: - Postal Code (Singapore 6 digits)

    static func isValidPostalCode(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        guard digits.count == 6 else { return false }

        // Singapore postal codes: first two digits indicate district (01-82)
        // Basic range check for realistic postal codes
        guard let firstTwo = Int(String(digits.prefix(2))), firstTwo >= 1, firstTwo <= 82 else {
            return false
        }

        return true
    }

    // MARK: - Non-empty

    static func isNotEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Input Sanitization

    /// Sanitizes user input by trimming whitespace, normalizing spaces,
    /// and removing control characters.
    static func sanitizeInput(_ value: String) -> String {
        var result = value

        // Remove control characters (except newline for multiline fields)
        result = result.unicodeScalars
            .filter { !$0.properties.isDefaultIgnorableCodePoint && ($0.value >= 32 || $0 == "\n" || $0 == "\t") }
            .map { Character($0) }
            .map(String.init)
            .joined()

        // Trim leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Collapse multiple spaces into one
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        return result
    }

    /// Sanitizes and normalizes a phone number string for consistent storage.
    /// Strips spaces, dashes, parentheses. Ensures +65 prefix for SG numbers.
    static func sanitizePhone(_ value: String) -> String {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "+")).inverted).joined()

        // If it's a bare 8-digit SG number, add +65
        if cleaned.count == 8 && !cleaned.hasPrefix("+") && !cleaned.hasPrefix("65") {
            return "+65\(cleaned)"
        }

        // If it starts with 65 and is 10 digits, add +
        if cleaned.hasPrefix("65") && cleaned.count == 10 && !cleaned.hasPrefix("+") {
            return "+\(cleaned)"
        }

        // If it already has +65, keep it
        if cleaned.hasPrefix("+65") {
            return cleaned
        }

        return cleaned
    }

    /// Ensures postal code is digits only, trimmed.
    static func sanitizePostalCode(_ value: String) -> String {
        return value.filter { $0.isNumber }
    }
}
