import Foundation

class SlackService {

    func sendNotification(for applicant: ApplicantData) async throws {
        guard let url = URL(string: SlackConfig.webhookURL) else {
            throw SlackError.invalidWebhookURL
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let startDate = dateFormatter.string(from: applicant.earliestStartDate)

        let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
        let salary = applicant.expectedSalary.isEmpty ? "Not specified" : "SGD $\(applicant.expectedSalary)"

        let blocks: [[String: Any]] = [
            [
                "type": "section",
                "text": [
                    "type": "mrkdwn",
                    "text": "🟠 *New Walk-In Applicant Registration*"
                ]
            ],
            [
                "type": "section",
                "text": [
                    "type": "mrkdwn",
                    "text": """
                    *Name:* \(applicant.fullName) (\(applicant.preferredName))
                    *Position(s):* \(positions)
                    *Contact:* \(applicant.contactNumber) | \(applicant.emailAddress)
                    *Nationality:* \(applicant.nationality.rawValue)
                    *Experience:* \(applicant.totalExperience.rawValue)
                    *Expected Salary:* \(salary)
                    *Available From:* \(startDate)
                    *Referral Source:* \(applicant.howDidYouHear.rawValue)
                    *Reference:* `\(applicant.referenceNumber)`
                    """
                ]
            ],
            [
                "type": "context",
                "elements": [
                    [
                        "type": "mrkdwn",
                        "text": "📄 PDF and JSON uploaded to Google Drive."
                    ]
                ]
            ]
        ]

        let payload: [String: Any] = ["blocks": blocks]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SlackError.sendFailed
        }
    }
}

enum SlackError: LocalizedError {
    case invalidWebhookURL
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .invalidWebhookURL: return "Invalid Slack webhook URL"
        case .sendFailed: return "Failed to send Slack notification"
        }
    }
}
