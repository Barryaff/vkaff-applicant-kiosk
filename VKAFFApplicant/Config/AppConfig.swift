import Foundation

enum AppConfig {
    static let appVersion = "1.0.0"
    static let referencePrefix = "AFF"
    static let adminPIN = "000000"
    static let idleWarningSeconds: TimeInterval = 90
    static let idleResetSeconds: TimeInterval = 120
    static let confirmationAutoReturnSeconds: TimeInterval = 15
    static let maxRetryAttempts = 3
    static let maxQualifications = 5
    static let maxEmploymentRecords = 5
}
