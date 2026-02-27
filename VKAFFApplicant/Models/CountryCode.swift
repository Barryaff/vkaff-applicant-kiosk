import Foundation

struct CountryCode: Identifiable, Hashable, Codable {
    let id: String  // ISO 3166-1 alpha-2
    let name: String
    let dialCode: String

    // Pinned at top for easy access
    static let singapore = CountryCode(id: "SG", name: "Singapore", dialCode: "+65")
    static let malaysia = CountryCode(id: "MY", name: "Malaysia", dialCode: "+60")

    static let all: [CountryCode] = [
        // Pinned
        singapore,
        malaysia,
        // Rest alphabetically
        CountryCode(id: "AU", name: "Australia", dialCode: "+61"),
        CountryCode(id: "BD", name: "Bangladesh", dialCode: "+880"),
        CountryCode(id: "BN", name: "Brunei", dialCode: "+673"),
        CountryCode(id: "KH", name: "Cambodia", dialCode: "+855"),
        CountryCode(id: "CN", name: "China", dialCode: "+86"),
        CountryCode(id: "HK", name: "Hong Kong", dialCode: "+852"),
        CountryCode(id: "IN", name: "India", dialCode: "+91"),
        CountryCode(id: "ID", name: "Indonesia", dialCode: "+62"),
        CountryCode(id: "JP", name: "Japan", dialCode: "+81"),
        CountryCode(id: "KR", name: "South Korea", dialCode: "+82"),
        CountryCode(id: "LA", name: "Laos", dialCode: "+856"),
        CountryCode(id: "MO", name: "Macau", dialCode: "+853"),
        CountryCode(id: "MM", name: "Myanmar", dialCode: "+95"),
        CountryCode(id: "NP", name: "Nepal", dialCode: "+977"),
        CountryCode(id: "NZ", name: "New Zealand", dialCode: "+64"),
        CountryCode(id: "PK", name: "Pakistan", dialCode: "+92"),
        CountryCode(id: "PH", name: "Philippines", dialCode: "+63"),
        CountryCode(id: "LK", name: "Sri Lanka", dialCode: "+94"),
        CountryCode(id: "TW", name: "Taiwan", dialCode: "+886"),
        CountryCode(id: "TH", name: "Thailand", dialCode: "+66"),
        CountryCode(id: "GB", name: "United Kingdom", dialCode: "+44"),
        CountryCode(id: "US", name: "United States", dialCode: "+1"),
        CountryCode(id: "VN", name: "Vietnam", dialCode: "+84"),
    ]

    /// Display string for the picker button
    var flag: String {
        let base: UInt32 = 127397
        return id.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }.map(String.init).joined()
    }

    var pickerLabel: String {
        "\(flag) \(dialCode)"
    }

    var menuLabel: String {
        "\(flag) \(name) (\(dialCode))"
    }

    private static let dialCodeIndex: [String: CountryCode] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.dialCode, $0) })
    }()

    static func find(byDialCode code: String) -> CountryCode {
        dialCodeIndex[code] ?? singapore
    }
}
