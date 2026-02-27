import Foundation

enum AppConfig {
    static let skipValidation = false

    static let appVersion = "1.0.0"
    static let referencePrefix = "AFF"

    /// Admin PIN loaded from secrets.plist at runtime. Fallback to empty (login always fails).
    static var adminPIN: String {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let pin = dict["AdminPIN"] as? String,
              !pin.isEmpty else {
            return ""
        }
        return pin
    }
    static let idleWarningSeconds: TimeInterval = 600
    static let idleResetSeconds: TimeInterval = 630
    static let confirmationAutoReturnSeconds: TimeInterval = 15
    static let maxRetryAttempts = 3
    static let maxQualifications = 5
    static let maxEmploymentRecords = 5
    static let maxReferences = 2
    static let maxEmergencyContacts = 3
    static let maxSupportingDocuments = 5
    static let maxDocumentSizeMB = 10
}
