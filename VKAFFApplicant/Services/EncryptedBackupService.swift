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

// MARK: - Document Backup Manifest

struct BackupDocumentManifestEntry: Codable {
    let index: Int
    let fileName: String
    let mimeType: String
    let documentType: String
}

class EncryptedBackupService {

    /// Sanitizes a filename to prevent path traversal attacks.
    /// Strips directory separators, parent references, and null bytes.
    private func sanitizedFileName(_ name: String) -> String {
        var sanitized = name
            .replacingOccurrences(of: "..", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "\0", with: "")
        // Ensure non-empty after sanitization
        if sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sanitized = "unnamed_file"
        }
        return sanitized
    }

    private var backupDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("PendingUploads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        return dir
    }

    // MARK: - Save Backup

    func saveBackup(pdfData: Data, jsonData: Data, referenceNumber: String, supportingDocuments: [SupportingDocument] = []) throws {
        let pdfURL = backupDirectory.appendingPathComponent("\(referenceNumber).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(referenceNumber).json")

        do {
            try pdfData.write(to: pdfURL, options: .completeFileProtection)
            try jsonData.write(to: jsonURL, options: .completeFileProtection)

            // Save supporting documents alongside main backup
            for (index, doc) in supportingDocuments.enumerated() {
                let docURL = backupDirectory.appendingPathComponent("\(referenceNumber)_doc\(index)_\(sanitizedFileName(doc.fileName))")
                try doc.fileData.write(to: docURL, options: .completeFileProtection)
            }

            // Save document manifest so we can reconstruct on retry
            if !supportingDocuments.isEmpty {
                let manifest = supportingDocuments.enumerated().map { (index, doc) in
                    BackupDocumentManifestEntry(
                        index: index,
                        fileName: doc.fileName,
                        mimeType: doc.mimeType,
                        documentType: doc.documentType.rawValue
                    )
                }
                let manifestData = try JSONEncoder().encode(manifest)
                let manifestURL = backupDirectory.appendingPathComponent("\(referenceNumber)_docs_manifest.json")
                try manifestData.write(to: manifestURL, options: .completeFileProtection)
            }
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

    func getPendingData(for reference: String) -> (pdf: Data, json: Data, documents: [SupportingDocument])? {
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(reference).json")

        guard let pdfData = try? Data(contentsOf: pdfURL),
              let jsonData = try? Data(contentsOf: jsonURL) else {
            return nil
        }

        // Restore supporting documents from backup
        var documents: [SupportingDocument] = []
        let manifestURL = backupDirectory.appendingPathComponent("\(reference)_docs_manifest.json")
        if let manifestData = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode([BackupDocumentManifestEntry].self, from: manifestData) {
            for entry in manifest {
                let docURL = backupDirectory.appendingPathComponent("\(reference)_doc\(entry.index)_\(sanitizedFileName(entry.fileName))")
                if let docData = try? Data(contentsOf: docURL) {
                    let docType = DocumentType(rawValue: entry.documentType) ?? .others
                    documents.append(SupportingDocument(
                        documentType: docType,
                        fileName: entry.fileName,
                        fileData: docData,
                        mimeType: entry.mimeType
                    ))
                }
            }
        }

        return (pdfData, jsonData, documents)
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
        let fm = FileManager.default
        let pdfURL = backupDirectory.appendingPathComponent("\(reference).pdf")
        let jsonURL = backupDirectory.appendingPathComponent("\(reference).json")
        let manifestURL = backupDirectory.appendingPathComponent("\(reference)_docs_manifest.json")

        // Remove supporting document files
        if let manifestData = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode([BackupDocumentManifestEntry].self, from: manifestData) {
            for entry in manifest {
                let docURL = backupDirectory.appendingPathComponent("\(reference)_doc\(entry.index)_\(sanitizedFileName(entry.fileName))")
                try? fm.removeItem(at: docURL)
            }
        }

        try? fm.removeItem(at: pdfURL)
        try? fm.removeItem(at: jsonURL)
        try? fm.removeItem(at: manifestURL)

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
            removeBackup(for: ref)
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
                for (index, doc) in data.documents.enumerated() {
                    let docURL = exportDir.appendingPathComponent("\(ref)_Doc\(index + 1)_\(sanitizedFileName(doc.fileName))")
                    try? doc.fileData.write(to: docURL, options: .completeFileProtection)
                }
            }
        }

        return exportDir
    }
}
