import Foundation

enum Validators {
    // Cached regex patterns (avoid per-call compilation)
    private static let nricRegex = try! NSRegularExpression(pattern: "^[STFGM]\\d{7}[A-Z]$")
    private static let emailRegex = try! NSRegularExpression(pattern: "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")

    // MARK: - NRIC / FIN

    /// Validates Singapore NRIC/FIN with full checksum verification.
    /// S/T series: citizens/PRs born before/after 2000
    /// F/G series: foreigners issued FIN before/after 2000
    /// M series: foreigners issued FIN from 2022 onwards
    static func isValidNRIC(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces).uppercased()

        // Basic format check: prefix letter + 7 digits + checksum letter
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard nricRegex.firstMatch(in: trimmed, range: range) != nil else {
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
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return nricRegex.firstMatch(in: trimmed, range: range) != nil
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

        // Overall regex validation (uses cached NSRegularExpression)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return emailRegex.firstMatch(in: trimmed, range: range) != nil
    }

    // MARK: - Phone (International)

    /// Validates phone numbers — accepts international formats.
    /// - With country code (+XX...): total digits must be 7-15
    /// - Without country code: digits must be 7-15
    static func isValidPhone(_ value: String) -> Bool {
        let cleaned = value.filter { $0.isNumber || $0 == "+" }
        guard !cleaned.isEmpty else { return false }

        let digits = cleaned.filter { $0.isNumber }

        // International numbers: 7-15 digits (ITU-T E.164)
        guard digits.count >= 7 && digits.count <= 15 else { return false }

        // If starts with +, must be followed by digits
        if cleaned.hasPrefix("+") && digits.isEmpty { return false }

        return true
    }

    // MARK: - Postal Code (Singapore)

    /// Validates Singapore postal codes — exactly 6 digits, district 01-82.
    static func isValidPostalCode(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        guard digits.count == 6 else { return false }

        // District is the first two digits; valid range is 01-82
        let district = Int(digits.prefix(2)) ?? 0
        return district >= 1 && district <= 82
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
    /// Strips spaces, dashes, parentheses. Preserves + prefix and country code.
    static func sanitizePhone(_ value: String) -> String {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "+")).inverted).joined()

        // Ensure + prefix if it looks like an international number
        if cleaned.hasPrefix("+") {
            return cleaned
        }

        // If bare 8-digit SG number (starts with 6/8/9), add +65
        if cleaned.count == 8, let first = cleaned.first,
           first == "6" || first == "8" || first == "9" {
            return "+65\(cleaned)"
        }

        // If starts with country code digits (65...), add +
        if cleaned.hasPrefix("65") && cleaned.count == 10 {
            return "+\(cleaned)"
        }

        return cleaned
    }

    /// Strips non-digit characters from postal code for consistent storage.
    static func sanitizePostalCode(_ value: String) -> String {
        return value.filter { $0.isNumber }
    }
}
