import Foundation

enum ReferenceNumberGenerator {
    private static let lastDateKey = "lastReferenceDate"
    private static let lastSequenceKey = "lastReferenceSequence"
    private static let lock = NSLock()

    /// Generates a reference number in format: AFF-YYYYMMDD-XXXX
    static func generate() -> String {
        lock.lock()
        defer { lock.unlock() }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let todayStr = formatter.string(from: Date())

        let lastDate = UserDefaults.standard.string(forKey: lastDateKey) ?? ""
        var sequence: Int

        if lastDate == todayStr {
            sequence = UserDefaults.standard.integer(forKey: lastSequenceKey) + 1
        } else {
            sequence = 1
            UserDefaults.standard.set(todayStr, forKey: lastDateKey)
        }

        UserDefaults.standard.set(sequence, forKey: lastSequenceKey)

        let paddedSequence = String(format: "%04d", sequence)
        return "\(AppConfig.referencePrefix)-\(todayStr)-\(paddedSequence)"
    }
}
