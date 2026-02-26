import Foundation

enum SlackConfig {
    /// Loaded at runtime from Config/secrets.plist
    /// Set the key "SlackWebhookURL" in that file
    static var webhookURL: String {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["SlackWebhookURL"] as? String,
              !url.isEmpty else {
            print("[Slack] Warning: No webhook URL found in secrets.plist")
            return ""
        }
        return url
    }
}
