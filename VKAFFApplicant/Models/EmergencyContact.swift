import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var countryCode: String
    var phoneNumber: String
    var email: String
    var address: String
    var relationship: EmergencyRelationship
    var relationshipOther: String

    init(
        id: UUID = UUID(),
        name: String = "",
        countryCode: String = "+65",
        phoneNumber: String = "",
        email: String = "",
        address: String = "",
        relationship: EmergencyRelationship = .parent,
        relationshipOther: String = ""
    ) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = address
        self.relationship = relationship
        self.relationshipOther = relationshipOther
    }

    enum CodingKeys: String, CodingKey {
        case id, name, countryCode, phoneNumber, email, address, relationship, relationshipOther
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? "+65"
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        relationship = try container.decode(EmergencyRelationship.self, forKey: .relationship)
        relationshipOther = try container.decodeIfPresent(String.self, forKey: .relationshipOther) ?? ""
    }
}
