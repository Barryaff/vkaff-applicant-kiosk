import Foundation

enum GoogleDriveConfig {
    static let serviceAccountKeyPath = "service-account-key.json"

    static var folderID: String {
        secretsValue(forKey: "GoogleDriveFolderID") ?? ""
    }

    static var serviceAccountEmail: String {
        secretsValue(forKey: "GoogleDriveServiceAccountEmail") ?? ""
    }

    /// Impersonate this Workspace user via domain-wide delegation.
    /// Requires the service account's client ID to be authorized in Google Workspace Admin
    /// under Security > API Controls > Domain-wide Delegation with scope: https://www.googleapis.com/auth/drive.file
    static var impersonateEmail: String {
        secretsValue(forKey: "GoogleDriveImpersonateEmail") ?? ""
    }

    private static func secretsValue(forKey key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }
}
