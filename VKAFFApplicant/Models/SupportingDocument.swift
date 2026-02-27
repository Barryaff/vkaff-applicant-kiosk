import Foundation
import UIKit

struct SupportingDocument: Identifiable {
    let id: UUID
    var documentType: DocumentType
    var fileName: String
    var fileData: Data
    var mimeType: String
    var thumbnailData: Data?

    var fileSizeFormatted: String {
        let bytes = Double(fileData.count)
        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0f KB", bytes / 1024)
        } else {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        }
    }

    init(
        id: UUID = UUID(),
        documentType: DocumentType = .others,
        fileName: String = "",
        fileData: Data = Data(),
        mimeType: String = "application/octet-stream",
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.documentType = documentType
        self.fileName = fileName
        self.fileData = fileData
        self.mimeType = mimeType
        self.thumbnailData = thumbnailData
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case resume = "Resume / CV"
    case certificate = "Certificate / License"
    case idCopy = "ID / Passport Copy"
    case educationRecord = "Education Record"
    case others = "Others"
}

// MARK: - Metadata (for JSON export — excludes file binary data)

struct SupportingDocumentMetadata: Codable {
    let documentType: DocumentType
    let fileName: String
    let fileSize: Int

    init(from document: SupportingDocument) {
        self.documentType = document.documentType
        self.fileName = document.fileName
        self.fileSize = document.fileData.count
    }
}
