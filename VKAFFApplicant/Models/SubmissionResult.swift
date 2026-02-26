import Foundation

struct SubmissionResult {
    let success: Bool
    let referenceNumber: String
    let errorMessage: String?
    let driveFileURL: String?

    static func success(referenceNumber: String, driveFileURL: String? = nil) -> SubmissionResult {
        SubmissionResult(
            success: true,
            referenceNumber: referenceNumber,
            errorMessage: nil,
            driveFileURL: driveFileURL
        )
    }

    static func failure(message: String) -> SubmissionResult {
        SubmissionResult(
            success: false,
            referenceNumber: "",
            errorMessage: message,
            driveFileURL: nil
        )
    }
}
