import Foundation
import UIKit

class SubmissionViewModel {
    private let driveService = GoogleDriveService()
    private let slackService = SlackService()
    private let pdfGenerator = PDFGenerator()
    private let backupService = EncryptedBackupService()

    func submit(applicant: ApplicantData) async -> SubmissionResult {
        // Generate PDF
        let pdfData = pdfGenerator.generate(from: applicant)

        // Generate JSON
        let jsonData: Data
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            jsonData = try encoder.encode(applicant)
        } catch {
            return .failure(message: "Failed to encode application data: \(error.localizedDescription)")
        }

        let sanitizedName = applicant.fullName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let baseFileName = "AFF_Application_\(sanitizedName)_\(dateStr)_\(applicant.referenceNumber)"

        // Attempt upload
        var retryCount = 0
        var lastError: String?

        while retryCount < AppConfig.maxRetryAttempts {
            do {
                // Upload PDF
                try await driveService.uploadFile(
                    data: pdfData,
                    fileName: "\(baseFileName).pdf",
                    mimeType: "application/pdf"
                )

                // Upload JSON
                try await driveService.uploadFile(
                    data: jsonData,
                    fileName: "\(baseFileName).json",
                    mimeType: "application/json"
                )

                // Send Slack notification
                try await slackService.sendNotification(for: applicant)

                return .success(referenceNumber: applicant.referenceNumber)
            } catch {
                retryCount += 1
                lastError = error.localizedDescription
                if retryCount < AppConfig.maxRetryAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(retryCount) * 2_000_000_000)
                }
            }
        }

        // All retries failed - save locally
        do {
            try backupService.saveBackup(
                pdfData: pdfData,
                jsonData: jsonData,
                referenceNumber: applicant.referenceNumber
            )
        } catch {
            // Even backup failed
        }

        return .failure(message: lastError ?? "Upload failed after \(AppConfig.maxRetryAttempts) attempts. Data saved locally.")
    }
}
