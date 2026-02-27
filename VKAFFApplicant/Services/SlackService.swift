import Foundation

class SlackService {

    private static let placeholderWebhookURL = "PLACEHOLDER_WEBHOOK_URL"
    private static let retryDelay: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    private static let maxRetries = 1

    func sendNotification(for applicant: ApplicantData) async throws {
        // Skip silently if webhook URL is the placeholder
        guard SlackConfig.webhookURL != Self.placeholderWebhookURL else {
            return
        }

        guard let url = URL(string: SlackConfig.webhookURL) else {
            throw SlackError.invalidWebhookURL
        }

        let payload = buildPayload(for: applicant)
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Retry logic: 1 retry with 2s delay
        var lastError: Error?
        for attempt in 0...Self.maxRetries {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw SlackError.sendFailed
                }

                return // Success
            } catch {
                lastError = error
                if attempt < Self.maxRetries {
                    try? await Task.sleep(nanoseconds: Self.retryDelay)
                }
            }
        }

        throw lastError ?? SlackError.sendFailed
    }

    // MARK: - Block Kit Payload Builder

    private func buildPayload(for applicant: ApplicantData) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let startDate = dateFormatter.string(from: applicant.earliestStartDate)

        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "dd MMM yyyy, h:mm a"
        let timestamp = timestampFormatter.string(from: Date())

        let positions = applicant.positionsAppliedFor.map(\.rawValue).joined(separator: ", ")
        let salary = applicant.expectedSalary.isEmpty ? "Not specified" : "SGD $\(applicant.expectedSalary)"
        let driveURL = "https://drive.google.com/drive/search?q=\(applicant.referenceNumber)"

        let blocks: [[String: Any]] = [
            // Header block
            [
                "type": "header",
                "text": [
                    "type": "plain_text",
                    "text": "New Applicant Registration",
                    "emoji": true
                ]
            ],
            // Divider
            [
                "type": "divider"
            ],
            // Applicant identity section - two column fields
            [
                "type": "section",
                "fields": [
                    [
                        "type": "mrkdwn",
                        "text": "*Name:*\n\(applicant.fullName) (\(applicant.preferredName))"
                    ],
                    [
                        "type": "mrkdwn",
                        "text": "*Reference:*\n`\(applicant.referenceNumber)`"
                    ]
                ]
            ],
            // Nationality section
            [
                "type": "section",
                "fields": [
                    [
                        "type": "mrkdwn",
                        "text": "*Nationality:*\n\(applicant.nationality == .others ? (applicant.nationalityOther.isEmpty ? "Others" : applicant.nationalityOther) : applicant.nationality.rawValue)"
                    ],
                    [
                        "type": "mrkdwn",
                        "text": "*Experience:*\n\(applicant.totalExperience.rawValue)"
                    ]
                ]
            ],
            // Position & salary section - two column fields
            [
                "type": "section",
                "fields": [
                    [
                        "type": "mrkdwn",
                        "text": "*Position(s):*\n\(positions)"
                    ],
                    [
                        "type": "mrkdwn",
                        "text": "*Expected Salary:*\n\(salary)"
                    ]
                ]
            ],
            // Start date & referral section - two column fields
            [
                "type": "section",
                "fields": [
                    [
                        "type": "mrkdwn",
                        "text": "*Available From:*\n\(startDate)"
                    ],
                    [
                        "type": "mrkdwn",
                        "text": "*Referral Source:*\n\(applicant.howDidYouHear.rawValue)"
                    ]
                ]
            ],
            // Divider before actions
            [
                "type": "divider"
            ],
            // Actions block with View in Drive button
            [
                "type": "actions",
                "elements": [
                    [
                        "type": "button",
                        "text": [
                            "type": "plain_text",
                            "text": "View in Drive",
                            "emoji": true
                        ],
                        "url": driveURL,
                        "action_id": "view_in_drive_\(applicant.referenceNumber)"
                    ]
                ]
            ],
            // Context block with timestamp and app version
            [
                "type": "context",
                "elements": [
                    [
                        "type": "mrkdwn",
                        "text": "Submitted \(timestamp) | VKAFF Kiosk v\(AppConfig.appVersion)"
                    ]
                ]
            ]
        ]

        return ["blocks": blocks]
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
