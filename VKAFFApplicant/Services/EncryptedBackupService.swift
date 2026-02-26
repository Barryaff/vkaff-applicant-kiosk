import Foundation

class EncryptedBackupService {

    private var backupDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("PendingUploads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Save Backup

    func saveBackup(pdfData: Data, jsonData: Data, referenceNumber: String) throws {
        let pdfURL = backupDirectory.appendingPathComponent("\(referenceNumber).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(referenceNumber).json")

        try pdfData.write(to: pdfURL, options: .completeFileProtection)
        try jsonData.write(to: jsonURL, options: .completeFileProtection)

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

    // MARK: - Export All

    func exportAll() -> URL? {
        let pending = getPendingReferences()
        guard !pending.isEmpty else { return nil }

        let exportDir = FileManager.default.temporaryDirectory.appendingPathComponent("VKAFFExport_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

        for ref in pending {
            if let data = getPendingData(for: ref) {
                try? data.pdf.write(to: exportDir.appendingPathComponent("\(ref).pdf"))
                try? data.json.write(to: exportDir.appendingPathComponent("\(ref).json"))
            }
        }

        return exportDir
    }
}
