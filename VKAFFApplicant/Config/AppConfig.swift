import Foundation

enum AppConfig {
    /// Set to true to skip all form validation (for testing). Remember to set back to false before release.
    static let skipValidation = true

    static let appVersion = "1.0.0"
    static let referencePrefix = "AFF"
    static let adminPIN = "000000"
    static let idleWarningSeconds: TimeInterval = 600
    static let idleResetSeconds: TimeInterval = 630
    static let confirmationAutoReturnSeconds: TimeInterval = 15
    static let maxRetryAttempts = 3
    static let maxQualifications = 5
    static let maxEmploymentRecords = 5
    static let maxReferences = 2
}
