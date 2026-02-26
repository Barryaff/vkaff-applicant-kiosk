import Foundation
import Security

class GoogleDriveService {

    // MARK: - Upload File

    func uploadFile(data: Data, fileName: String, mimeType: String) async throws {
        let accessToken = try await getAccessToken()

        let boundary = UUID().uuidString
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

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

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.uploadFailed
        }
    }

    // MARK: - JWT Authentication

    private func getAccessToken() async throws -> String {
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

        let tokenBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        tokenRequest.httpBody = tokenBody.data(using: String.Encoding.utf8)

        let (data, _) = try await URLSession.shared.data(for: tokenRequest)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

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
    case uploadFailed
    case jwtCreationFailed
    case missingServiceAccountKey
    case invalidServiceAccountKey

    var errorDescription: String? {
        switch self {
        case .uploadFailed: return "Failed to upload file to Google Drive"
        case .jwtCreationFailed: return "Failed to create authentication token"
        case .missingServiceAccountKey: return "Service account key file not found"
        case .invalidServiceAccountKey: return "Invalid service account key"
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
