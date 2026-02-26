import Foundation

struct EmploymentRecord: Identifiable, Codable {
    let id: UUID
    var companyName: String
    var jobTitle: String
    var industry: Industry
    var fromDate: Date
    var toDate: Date
    var isCurrentPosition: Bool
    var reasonForLeaving: ReasonForLeaving
    var keyResponsibilities: String

    init(
        id: UUID = UUID(),
        companyName: String = "",
        jobTitle: String = "",
        industry: Industry = .others,
        fromDate: Date = Date(),
        toDate: Date = Date(),
        isCurrentPosition: Bool = false,
        reasonForLeaving: ReasonForLeaving = .preferNotToSay,
        keyResponsibilities: String = ""
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.industry = industry
        self.fromDate = fromDate
        self.toDate = toDate
        self.isCurrentPosition = isCurrentPosition
        self.reasonForLeaving = reasonForLeaving
        self.keyResponsibilities = keyResponsibilities
    }
}

enum Industry: String, Codable, CaseIterable {
    case fnbManufacturing = "Food & Beverage Manufacturing"
    case flavoursFragrances = "Flavours & Fragrances"
    case chemicalManufacturing = "Chemical Manufacturing"
    case fmcg = "FMCG"
    case pharmaceutical = "Pharmaceutical"
    case logisticsWarehousing = "Logistics & Warehousing"
    case retail = "Retail"
    case fnbHospitality = "F&B / Hospitality"
    case bankingFinance = "Banking & Finance"
    case itTechnology = "IT / Technology"
    case governmentPublic = "Government / Public Sector"
    case others = "Others"
}

enum ReasonForLeaving: String, Codable, CaseIterable {
    case careerAdvancement = "Career advancement"
    case endOfContract = "End of contract"
    case retrenchment = "Retrenchment"
    case personalReasons = "Personal reasons"
    case relocating = "Relocating"
    case betterCompensation = "Better compensation"
    case preferNotToSay = "Prefer not to say"
}
