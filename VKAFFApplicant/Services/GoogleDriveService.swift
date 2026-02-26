import Foundation
import Security

class GoogleDriveService {

    // MARK: - Token Cache

    /// Cached access token and its expiry time.
    /// Tokens are valid for 1 hour; we refresh 5 minutes early to avoid edge cases.
    private static var cachedToken: String?
    private static var tokenExpiry: Date?
    private static let tokenRefreshMargin: TimeInterval = 300 // 5 minutes early

    // MARK: - URLSession with Timeout

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // MARK: - Upload File

    func uploadFile(data: Data, fileName: String, mimeType: String) async throws {
        let accessToken = try await getAccessToken()

        let boundary = UUID().uuidString
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Build multipart body
        var body = Data()

        // Metadata part
        let metadata: [String: Any] = [
            "name": fileName,
            "parents": [GoogleDriveConfig.folderID]
        ]
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataJSON)
        body.append("\r\n".data(using: .utf8)!)

        // File part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DriveError.uploadFailed(statusCode: nil, message: "Invalid response from server")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Parse error response from Google Drive API
            let errorMessage = parseGoogleDriveError(from: responseData, statusCode: httpResponse.statusCode)

            // If we got a 401, invalidate the cached token so the next attempt refreshes it
            if httpResponse.statusCode == 401 {
                GoogleDriveService.cachedToken = nil
                GoogleDriveService.tokenExpiry = nil
            }

            throw DriveError.uploadFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }

    // MARK: - Error Parsing

    /// Parses Google Drive API error responses to extract meaningful error messages.
    private func parseGoogleDriveError(from data: Data, statusCode: Int) -> String {
        // Try to parse the JSON error response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown error"
            let code = error["code"] as? Int ?? statusCode

            // Check for specific error reasons
            if let errors = error["errors"] as? [[String: Any]],
               let firstError = errors.first {
                let reason = firstError["reason"] as? String ?? ""
                switch reason {
                case "notFound":
                    return "Google Drive folder not found. Please check the folder ID configuration."
                case "forbidden", "insufficientPermissions":
                    return "Insufficient permissions to upload to the specified Google Drive folder."
                case "storageQuotaExceeded":
                    return "Google Drive storage quota exceeded."
                case "rateLimitExceeded", "userRateLimitExceeded":
                    return "Too many requests to Google Drive. Please wait a moment."
                case "authError":
                    return "Authentication failed. The service account credentials may have expired."
                default:
                    return "Google Drive error (\(code)): \(message)"
                }
            }

            return "Google Drive error (\(code)): \(message)"
        }

        // Fallback: generic message based on status code
        switch statusCode {
        case 400:
            return "Bad request to Google Drive API"
        case 401:
            return "Authentication expired. Re-authenticating on next attempt."
        case 403:
            return "Access denied to Google Drive folder"
        case 404:
            return "Google Drive upload endpoint or folder not found"
        case 429:
            return "Rate limited by Google Drive API"
        case 500...599:
            return "Google Drive server error (HTTP \(statusCode))"
        default:
            return "Upload failed with HTTP status \(statusCode)"
        }
    }

    // MARK: - JWT Authentication with Token Caching

    private func getAccessToken() async throws -> String {
        // Return cached token if still valid
        if let token = GoogleDriveService.cachedToken,
           let expiry = GoogleDriveService.tokenExpiry,
           Date() < expiry {
            return token
        }

        // Token is expired or doesn't exist - create a new one
        let now = Date()
        let expiry = now.addingTimeInterval(3600)

        let header: [String: Any] = [
            "alg": "RS256",
            "typ": "JWT"
        ]

        let claims: [String: Any] = [
            "iss": GoogleDriveConfig.serviceAccountEmail,
            "scope": "https://www.googleapis.com/auth/drive.file",
            "aud": "https://oauth2.googleapis.com/token",
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiry.timeIntervalSince1970)
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)

        let headerBase64 = headerData.base64URLEncoded()
        let claimsBase64 = claimsData.base64URLEncoded()

        let signingInput = "\(headerBase64).\(claimsBase64)"

        // Load private key from bundled service account JSON
        let privateKey = try loadPrivateKey()

        guard let signingData = signingInput.data(using: .utf8) else {
            throw DriveError.jwtCreationFailed
        }

        var cfError: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            signingData as CFData,
            &cfError
        ) else {
            throw DriveError.jwtCreationFailed
        }

        let signatureBase64 = (signature as Data).base64URLEncoded()
        let jwt = "\(signingInput).\(signatureBase64)"

        // Exchange JWT for access token
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var tokenRequest = URLRequest(url: tokenURL)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        tokenRequest.timeoutInterval = 15

        let tokenBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        tokenRequest.httpBody = tokenBody.data(using: String.Encoding.utf8)

        let (data, response) = try await session.data(for: tokenRequest)

        // Check for HTTP errors on token request
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            // Attempt to parse error details
            let errorDetail: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDesc = json["error_description"] as? String {
                errorDetail = errorDesc
            } else {
                errorDetail = "HTTP \(httpResponse.statusCode)"
            }
            throw DriveError.tokenRequestFailed(detail: errorDetail)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Cache the token with a refresh margin (refresh 5 minutes before actual expiry)
        GoogleDriveService.cachedToken = tokenResponse.accessToken
        GoogleDriveService.tokenExpiry = now.addingTimeInterval(
            TimeInterval(tokenResponse.expiresIn) - GoogleDriveService.tokenRefreshMargin
        )

        return tokenResponse.accessToken
    }

    private func loadPrivateKey() throws -> SecKey {
        guard let keyURL = Bundle.main.url(forResource: "service-account-key", withExtension: "json") else {
            throw DriveError.missingServiceAccountKey
        }

        let keyData = try Data(contentsOf: keyURL)
        let keyJSON = try JSONSerialization.jsonObject(with: keyData) as? [String: Any]

        guard let pemString = keyJSON?["private_key"] as? String else {
            throw DriveError.invalidServiceAccountKey
        }

        // Strip PEM headers and decode
        let cleanPEM = pemString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")

        guard let keyBytes = Data(base64Encoded: cleanPEM) else {
            throw DriveError.invalidServiceAccountKey
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var cfError: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyBytes as CFData, attributes as CFDictionary, &cfError) else {
            throw DriveError.invalidServiceAccountKey
        }

        return key
    }
}

// MARK: - Supporting Types

private struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

enum DriveError: LocalizedError {
    case uploadFailed(statusCode: Int?, message: String)
    case jwtCreationFailed
    case missingServiceAccountKey
    case invalidServiceAccountKey
    case tokenRequestFailed(detail: String)

    var errorDescription: String? {
        switch self {
        case .uploadFailed(_, let message):
            return message
        case .jwtCreationFailed:
            return "Failed to create authentication token"
        case .missingServiceAccountKey:
            return "Service account key file not found"
        case .invalidServiceAccountKey:
            return "Invalid service account key"
        case .tokenRequestFailed(let detail):
            return "Token request failed: \(detail)"
        }
    }
}

// MARK: - Base64 URL Encoding

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
