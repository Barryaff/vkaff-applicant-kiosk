import Foundation

// MARK: - Error Types

enum BackupError: LocalizedError {
    case saveFailed(reference: String, underlying: Error)
    case readFailed(reference: String)
    case deleteFailed(reference: String, underlying: Error)
    case exportFailed(underlying: Error)
    case directoryCreationFailed(underlying: Error)
    case fileNotFound(reference: String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let ref, let err):
            return "Failed to save backup for \(ref): \(err.localizedDescription)"
        case .readFailed(let ref):
            return "Failed to read backup data for \(ref)"
        case .deleteFailed(let ref, let err):
            return "Failed to delete backup for \(ref): \(err.localizedDescription)"
        case .exportFailed(let err):
            return "Failed to export backups: \(err.localizedDescription)"
        case .directoryCreationFailed(let err):
            return "Failed to create backup directory: \(err.localizedDescription)"
        case .fileNotFound(let ref):
            return "Backup files not found for \(ref)"
        }
    }
}

// MARK: - Backup Metadata

struct BackupMetadata {
    let referenceNumber: String
    let applicantName: String
    let creationDate: Date
    let totalSize: Int64
}

class EncryptedBackupService {

    private var backupDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("PendingUploads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        return dir
    }

    // MARK: - Save Backup

    func saveBackup(pdfData: Data, jsonData: Data, referenceNumber: String) throws {
        let pdfURL = backupDirectory.appendingPathComponent("\(referenceNumber).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(referenceNumber).json")

        do {
            try pdfData.write(to: pdfURL, options: .completeFileProtection)
            try jsonData.write(to: jsonURL, options: .completeFileProtection)
        } catch {
            throw BackupError.saveFailed(reference: referenceNumber, underlying: error)
        }

        // Track pending uploads
        var pending = getPendingReferences()
        if !pending.contains(referenceNumber) {
            pending.append(referenceNumber)
            UserDefaults.standard.set(pending, forKey: "pendingUploadReferences")
        }
    }

    // MARK: - Get Pending

    func getPendingReferences() -> [String] {
        UserDefaults.standard.stringArray(forKey: "pendingUploadReferences") ?? []
    }

    func getPendingData(for reference: String) -> (pdf: Data, json: Data)? {
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(reference).json")

        guard let pdfData = try? Data(contentsOf: pdfURL),
              let jsonData = try? Data(contentsOf: jsonURL) else {
            return nil
        }

        return (pdfData, jsonData)
    }

    // MARK: - Backup Metadata

    /// Returns the creation date of the backup files for a given reference number.
    func getCreationDate(for reference: String) -> Date? {
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let attributes = try? FileManager.default.attributesOfItem(atPath: pdfURL.path)
        return attributes?[.creationDate] as? Date
    }

    /// Returns metadata for a given backup reference, parsing the applicant name from the JSON file.
    func getBackupMetadata(for reference: String) -> BackupMetadata? {
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(reference).json")

        let fm = FileManager.default
        guard fm.fileExists(atPath: pdfURL.path),
              fm.fileExists(atPath: jsonURL.path) else {
            return nil
        }

        let pdfAttributes = try? fm.attributesOfItem(atPath: pdfURL.path)
        let jsonAttributes = try? fm.attributesOfItem(atPath: jsonURL.path)

        let pdfSize = (pdfAttributes?[.size] as? Int64) ?? 0
        let jsonSize = (jsonAttributes?[.size] as? Int64) ?? 0
        let creationDate = (pdfAttributes?[.creationDate] as? Date) ?? Date()

        // Parse applicant name from JSON
        var applicantName = "Unknown"
        if let jsonData = try? Data(contentsOf: jsonURL),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let fullName = json["fullName"] as? String {
            applicantName = fullName
        }

        return BackupMetadata(
            referenceNumber: reference,
            applicantName: applicantName,
            creationDate: creationDate,
            totalSize: pdfSize + jsonSize
        )
    }

    /// Returns the total size in bytes of all pending backup files.
    func getTotalPendingSize() -> Int64 {
        let pending = getPendingReferences()
        var totalSize: Int64 = 0
        let fm = FileManager.default

        for ref in pending {
            let pdfURL = backupDirectory.appendingPathComponent("\(ref).pdf")
            let jsonURL = backupDirectory.appendingPathComponent("\(ref).json")

            if let pdfAttrs = try? fm.attributesOfItem(atPath: pdfURL.path),
               let pdfSize = pdfAttrs[.size] as? Int64 {
                totalSize += pdfSize
            }
            if let jsonAttrs = try? fm.attributesOfItem(atPath: jsonURL.path),
               let jsonSize = jsonAttrs[.size] as? Int64 {
                totalSize += jsonSize
            }
        }

        return totalSize
    }

    /// Returns a human-readable string for the total pending backup size.
    func formattedTotalPendingSize() -> String {
        let bytes = getTotalPendingSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Remove Completed

    func removeBackup(for reference: String) {
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(reference).json")

        try? FileManager.default.removeItem(at: pdfURL)
        try? FileManager.default.removeItem(at: jsonURL)

        var pending = getPendingReferences()
        pending.removeAll { $0 == reference }
        UserDefaults.standard.set(pending, forKey: "pendingUploadReferences")
    }

    /// Removes all pending backups. Returns the number of backups removed.
    @discardableResult
    func removeAllBackups() -> Int {
        let pending = getPendingReferences()
        let count = pending.count

        for ref in pending {
            let pdfURL = backupDirectory.appendingPathComponent("\(ref).pdf")
            let jsonURL = backupDirectory.appendingPathComponent("\(ref).json")
            try? FileManager.default.removeItem(at: pdfURL)
            try? FileManager.default.removeItem(at: jsonURL)
        }

        UserDefaults.standard.set([String](), forKey: "pendingUploadReferences")
        return count
    }

    // MARK: - Export All

    func exportAll() -> URL? {
        let pending = getPendingReferences()
        guard !pending.isEmpty else { return nil }

        let exportDir = FileManager.default.temporaryDirectory.appendingPathComponent("VKAFFExport_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

        for ref in pending {
            if let data = getPendingData(for: ref) {
                let pdfURL = exportDir.appendingPathComponent("\(ref).pdf")
                let jsonURL = exportDir.appendingPathComponent("\(ref).json")
                try? data.pdf.write(to: pdfURL, options: .completeFileProtection)
                try? data.json.write(to: jsonURL, options: .completeFileProtection)
            }
        }

        return exportDir
    }
}
