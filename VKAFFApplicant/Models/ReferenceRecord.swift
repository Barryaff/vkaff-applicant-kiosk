import Foundation

struct ReferenceRecord: Identifiable, Codable {
    let id: UUID
    var name: String
    var relationship: String
    var contactCountryCode: String
    var contactNumber: String
    var email: String
    var yearsKnown: String

    init(
        id: UUID = UUID(),
        name: String = "",
        relationship: String = "",
        contactCountryCode: String = "+65",
        contactNumber: String = "",
        email: String = "",
        yearsKnown: String = ""
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.contactCountryCode = contactCountryCode
        self.contactNumber = contactNumber
        self.email = email
        self.yearsKnown = yearsKnown
    }

    enum CodingKeys: String, CodingKey {
        case id, name, relationship, contactCountryCode, contactNumber, email, yearsKnown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        relationship = try container.decode(String.self, forKey: .relationship)
        contactCountryCode = try container.decodeIfPresent(String.self, forKey: .contactCountryCode) ?? "+65"
        contactNumber = try container.decode(String.self, forKey: .contactNumber)
        email = try container.decode(String.self, forKey: .email)
        yearsKnown = try container.decode(String.self, forKey: .yearsKnown)
    }
}
