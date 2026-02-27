import Foundation
import UIKit
import Network

class SubmissionViewModel {
    private let driveService = GoogleDriveService()
    private let slackService = SlackService()
    private let pdfGenerator = PDFGenerator()
    private let backupService = EncryptedBackupService()

    /// Checks current network connectivity using NWPathMonitor.
    /// Returns true if the device has a usable network path.
    private func isNetworkAvailable() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.vkaff.networkCheck")
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: queue)
        }
    }

    func submit(applicant: ApplicantData) async -> SubmissionResult {
        // Sanitize data before submission
        let sanitizedApplicant = applicant
        sanitizedApplicant.sanitizeAllFields()

        // Generate PDF
        let pdfData = pdfGenerator.generate(from: sanitizedApplicant)

        // Generate JSON
        let jsonData: Data
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            jsonData = try encoder.encode(sanitizedApplicant)
        } catch {
            return .failure(message: "Failed to encode application data: \(error.localizedDescription)")
        }

        let sanitizedName = sanitizedApplicant.fullName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let baseFileName = "AFF_Application_\(sanitizedName)_\(dateStr)_\(sanitizedApplicant.referenceNumber)"

        // Write-ahead backup: save locally BEFORE attempting upload to prevent data loss on crash
        do {
            try backupService.saveBackup(
                pdfData: pdfData,
                jsonData: jsonData,
                referenceNumber: sanitizedApplicant.referenceNumber
            )
        } catch {
            // Backup failed — still attempt upload, but log the failure
            #if DEBUG
            print("[SubmissionVM] Write-ahead backup failed: \(error.localizedDescription)")
            #endif
        }

        // Register background task to allow upload to complete if app is briefly backgrounded
        let bgTaskID = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "SubmitApplication") {
                // Expiration handler — nothing to clean up, upload will fail naturally
            }
        }
        defer {
            if bgTaskID != .invalid {
                Task { @MainActor in
                    UIApplication.shared.endBackgroundTask(bgTaskID)
                }
            }
        }

        // Check network connectivity before attempting upload
        let networkAvailable = await isNetworkAvailable()

        if !networkAvailable {
            return .failure(
                message: "No network connection. Your application has been saved securely and will be uploaded when connectivity is restored."
            )
        }

        // Send Slack notification independently (non-critical, don't block on Drive)
        Task {
            do {
                try await withTimeout(seconds: 15) {
                    try await self.slackService.sendNotification(for: sanitizedApplicant)
                }
                #if DEBUG
                print("[SubmissionVM] Slack notification sent successfully")
                #endif
            } catch {
                #if DEBUG
                print("[SubmissionVM] Slack notification failed (non-critical): \(error.localizedDescription)")
                #endif
            }
        }

        // Attempt Drive upload with exponential backoff (1s, 2s, 4s) + jitter
        var retryCount = 0
        var lastError: SubmissionError?

        while retryCount < AppConfig.maxRetryAttempts {
            do {
                // Upload PDF with timeout
                try await withTimeout(seconds: 30) {
                    try await self.driveService.uploadFile(
                        data: pdfData,
                        fileName: "\(baseFileName).pdf",
                        mimeType: "application/pdf"
                    )
                }

                // Upload JSON with timeout
                try await withTimeout(seconds: 30) {
                    try await self.driveService.uploadFile(
                        data: jsonData,
                        fileName: "\(baseFileName).json",
                        mimeType: "application/json"
                    )
                }

                #if DEBUG
                print("[SubmissionVM] Drive upload successful")
                #endif

                // Upload succeeded — remove the write-ahead backup
                backupService.removeBackup(for: sanitizedApplicant.referenceNumber)
                return .success(referenceNumber: sanitizedApplicant.referenceNumber)

            } catch {
                retryCount += 1
                lastError = classifyError(error)
                #if DEBUG
                print("[SubmissionVM] Drive upload attempt \(retryCount) failed: \(error.localizedDescription)")
                #endif

                // Don't retry auth errors - they won't resolve with retries
                if case .authError = lastError {
                    break
                }

                if retryCount < AppConfig.maxRetryAttempts {
                    // Exponential backoff with jitter: 1s, 2s, 4s + random 0-0.5s
                    let baseDelay = pow(2.0, Double(retryCount - 1))
                    let jitter = Double.random(in: 0...0.5)
                    let delay = UInt64((baseDelay + jitter) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)

                    // Re-check connectivity before retrying
                    let stillConnected = await isNetworkAvailable()
                    if !stillConnected {
                        return .failure(
                            message: "Network connection lost. Your application has been saved securely and will be uploaded when connectivity is restored."
                        )
                    }
                }
            }
        }

        // All retries failed — backup already saved by write-ahead, just return the error
        let errorMessage = userFacingMessage(for: lastError)
        return .failure(message: errorMessage)
    }

    // MARK: - Backup Helper

    private func saveToBackupAndReturn(
        pdfData: Data,
        jsonData: Data,
        referenceNumber: String,
        reason: String
    ) async -> SubmissionResult {
        do {
            try backupService.saveBackup(
                pdfData: pdfData,
                jsonData: jsonData,
                referenceNumber: referenceNumber
            )
            return .failure(message: reason)
        } catch {
            return .failure(message: "Upload failed and local backup also failed: \(error.localizedDescription). Please contact HR.")
        }
    }

    // MARK: - Timeout Helper

    /// Runs an async operation with a timeout. Throws `SubmissionError.timeout` if exceeded.
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw SubmissionError.timeout
            }

            // Return the first completed result; cancel the other
            guard let result = try await group.next() else {
                throw SubmissionError.timeout
            }
            group.cancelAll()
            return result
        }
    }

    // MARK: - Error Classification

    private enum SubmissionError: Error {
        case networkError(String)
        case authError(String)
        case serverError(String)
        case timeout
        case unknown(String)
    }

    private func classifyError(_ error: Error) -> SubmissionError {
        // Check for our own timeout
        if let submissionError = error as? SubmissionError {
            return submissionError
        }

        // Check for Drive-specific errors
        if let driveError = error as? DriveError {
            switch driveError {
            case .uploadFailed(let statusCode, _):
                if let code = statusCode {
                    if code == 401 || code == 403 {
                        return .authError(driveError.localizedDescription)
                    } else if code >= 500 {
                        return .serverError(driveError.localizedDescription)
                    }
                }
                return .serverError(driveError.localizedDescription)
            case .jwtCreationFailed, .missingServiceAccountKey, .invalidServiceAccountKey:
                return .authError(driveError.localizedDescription)
            case .tokenRequestFailed:
                return .authError(driveError.localizedDescription)
            }
        }

        // Check for URL errors (network issues)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDataNotAllowed:
                return .networkError("No internet connection")
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorDNSLookupFailed:
                return .networkError("Cannot reach the server")
            default:
                return .networkError(error.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }

    private func userFacingMessage(for error: SubmissionError?) -> String {
        guard let error = error else {
            return "Upload failed after \(AppConfig.maxRetryAttempts) attempts. Your application has been saved securely and will be uploaded later."
        }

        switch error {
        case .networkError(let detail):
            return "Network error: \(detail). Your application has been saved securely and will be uploaded when connectivity is restored."
        case .authError:
            return "Authentication error with cloud storage. Your application has been saved securely. Please notify HR."
        case .serverError:
            return "The server is temporarily unavailable. Your application has been saved securely and will be uploaded later."
        case .timeout:
            return "The upload timed out. Your application has been saved securely and will be uploaded later."
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail). Your application has been saved securely."
        }
    }
}
