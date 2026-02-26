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
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true")!

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
            let rawBody = String(data: responseData, encoding: .utf8) ?? "no body"
            print("[GoogleDrive] Upload failed HTTP \(httpResponse.statusCode): \(rawBody)")
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

        // Build JWT claims. Use domain-wide delegation (sub) if impersonateEmail is set,
        // otherwise authenticate as the service account directly.
        var claims: [String: Any] = [
            "iss": GoogleDriveConfig.serviceAccountEmail,
            "scope": "https://www.googleapis.com/auth/drive.file",
            "aud": "https://oauth2.googleapis.com/token",
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiry.timeIntervalSince1970)
        ]
        if !GoogleDriveConfig.impersonateEmail.isEmpty {
            claims["sub"] = GoogleDriveConfig.impersonateEmail
        }

        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)

        let headerBase64 = headerData.base64URLEncoded()
        let claimsBase64 = claimsData.base64URLEncoded()

        let signingInput = "\(headerBase64).\(claimsBase64)"

        print("[GoogleDrive] JWT claims: iss=\(GoogleDriveConfig.serviceAccountEmail), sub=\(GoogleDriveConfig.impersonateEmail), scope=drive")

        // Load private key from bundled service account JSON
        let privateKey: SecKey
        do {
            privateKey = try loadPrivateKey()
            print("[GoogleDrive] Private key loaded successfully")
        } catch {
            print("[GoogleDrive] Failed to load private key: \(error)")
            throw error
        }

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
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorType = json["error"] as? String ?? ""
                let errorDesc = json["error_description"] as? String ?? ""
                errorDetail = "HTTP \(httpResponse.statusCode) - \(errorType): \(errorDesc)"
                print("[GoogleDrive] Token request failed: \(errorDetail)")
            } else {
                let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
                errorDetail = "HTTP \(httpResponse.statusCode): \(bodyStr)"
                print("[GoogleDrive] Token request failed: \(errorDetail)")
            }
            throw DriveError.tokenRequestFailed(detail: errorDetail)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        print("[GoogleDrive] Token obtained successfully, expires in \(tokenResponse.expiresIn)s")

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

        // Google service account keys are PKCS#8 format (BEGIN PRIVATE KEY).
        // SecKeyCreateWithData expects PKCS#1 (raw RSA key), so we strip the PKCS#8 ASN.1 wrapper.
        let rsaKeyData = stripPKCS8Header(from: keyBytes)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var cfError: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(rsaKeyData as CFData, attributes as CFDictionary, &cfError) else {
            throw DriveError.invalidServiceAccountKey
        }

        return key
    }

    /// Strips the PKCS#8 ASN.1 header to extract the inner PKCS#1 RSA private key.
    /// PKCS#8 structure: SEQUENCE { version, algorithmIdentifier, OCTET STRING { <PKCS#1 key> } }
    private func stripPKCS8Header(from data: Data) -> Data {
        let bytes = [UInt8](data)
        guard bytes.count > 26, bytes[0] == 0x30 else {
            return data // Not PKCS#8 or too short, return as-is
        }

        var index = 0

        // Skip outer SEQUENCE tag + length
        index += 1
        index += asn1LengthSize(bytes: bytes, from: index)

        // Skip version INTEGER (0x02 0x01 0x00)
        guard index < bytes.count, bytes[index] == 0x02 else { return data }
        index += 1
        let versionLen = Int(bytes[index])
        index += 1 + versionLen

        // Skip algorithm identifier SEQUENCE
        guard index < bytes.count, bytes[index] == 0x30 else { return data }
        index += 1
        let algLen = asn1Length(bytes: bytes, from: &index)
        index += algLen

        // Now at OCTET STRING (0x04) containing the PKCS#1 key
        guard index < bytes.count, bytes[index] == 0x04 else { return data }
        index += 1
        _ = asn1Length(bytes: bytes, from: &index)

        return Data(bytes[index...])
    }

    /// Returns the number of bytes used by an ASN.1 length field (not the length value itself).
    private func asn1LengthSize(bytes: [UInt8], from index: Int) -> Int {
        guard index < bytes.count else { return 1 }
        if bytes[index] & 0x80 == 0 {
            return 1
        }
        let numBytes = Int(bytes[index] & 0x7F)
        return 1 + numBytes
    }

    /// Reads an ASN.1 length and advances the index past it. Returns the length value.
    private func asn1Length(bytes: [UInt8], from index: inout Int) -> Int {
        guard index < bytes.count else { return 0 }
        if bytes[index] & 0x80 == 0 {
            let len = Int(bytes[index])
            index += 1
            return len
        }
        let numBytes = Int(bytes[index] & 0x7F)
        index += 1
        var length = 0
        for i in 0..<numBytes {
            guard index + i < bytes.count else { return 0 }
            length = length << 8 + Int(bytes[index + i])
        }
        index += numBytes
        return length
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
