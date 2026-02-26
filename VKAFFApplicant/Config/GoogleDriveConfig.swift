import Foundation

enum GoogleDriveConfig {
    static let folderID = "0AOEn__JFDLjgUk9PVA"
    static let serviceAccountEmail = "vkaff-registration-kiosk@vkaff-registration-kiosk.iam.gserviceaccount.com"
    static let serviceAccountKeyPath = "service-account-key.json"
    // Impersonate this Workspace user via domain-wide delegation.
    // Requires the service account's client ID to be authorized in Google Workspace Admin
    // under Security > API Controls > Domain-wide Delegation with scope: https://www.googleapis.com/auth/drive
    static let impersonateEmail = "support@advancedff.com"
}
