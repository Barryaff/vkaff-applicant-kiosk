import Foundation

class ApplicantData: ObservableObject, Codable {
    // MARK: - Personal Details
    @Published var fullName: String = ""
    @Published var preferredName: String = ""
    @Published var nricFIN: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var gender: Gender = .male
    @Published var nationality: NationalityStatus = .singaporeCitizen
    @Published var race: Race = .chinese
    @Published var raceOther: String = ""
    @Published var contactNumber: String = ""
    @Published var emailAddress: String = ""
    @Published var residentialAddress: String = ""
    @Published var postalCode: String = ""
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactNumber: String = ""
    @Published var emergencyContactRelationship: EmergencyRelationship = .parent

    // MARK: - Education & Qualifications
    @Published var highestQualification: HighestQualification = .diploma
    @Published var fieldOfStudy: String = ""
    @Published var institutionName: String = ""
    @Published var yearOfGraduation: Int = Calendar.current.component(.year, from: Date())
    @Published var additionalQualifications: [QualificationRecord] = []
    @Published var professionalCertifications: String = ""
    @Published var selectedLanguages: [LanguageProficiency] = []

    // MARK: - Work Experience
    @Published var totalExperience: TotalExperience = .freshGraduate
    @Published var employmentHistory: [EmploymentRecord] = []
    @Published var isCurrentlyEmployed: Bool = false
    @Published var noticePeriod: NoticePeriod = .immediate

    // MARK: - Position & Availability
    @Published var positionsAppliedFor: Set<Position> = []
    @Published var positionOther: String = ""
    @Published var preferredEmploymentType: EmploymentType = .fullTime
    @Published var earliestStartDate: Date = Date()
    @Published var expectedSalary: String = ""
    @Published var lastDrawnSalary: String = ""
    @Published var willingToWorkShifts: WillingnessOption = .openToDiscussion
    @Published var willingToTravel: TravelOption = .occasionally
    @Published var hasOwnTransport: Bool = false
    @Published var howDidYouHear: HearAboutUs = .walkIn
    @Published var referrerName: String = ""

    // MARK: - Declaration & Consent
    @Published var declarationAccuracy: Bool = false
    @Published var pdpaConsent: Bool = false
    @Published var backgroundCheckConsent: Bool = false
    @Published var hasMedicalCondition: MedicalDeclaration = .no
    @Published var medicalDetails: String = ""
    @Published var signatureData: Data? = nil
    @Published var submissionDate: Date = Date()

    // MARK: - Metadata
    @Published var referenceNumber: String = ""

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case fullName, preferredName, nricFIN, dateOfBirth, gender, nationality
        case race, raceOther, contactNumber, emailAddress, residentialAddress, postalCode
        case emergencyContactName, emergencyContactNumber, emergencyContactRelationship
        case highestQualification, fieldOfStudy, institutionName, yearOfGraduation
        case additionalQualifications, professionalCertifications, selectedLanguages
        case totalExperience, employmentHistory, isCurrentlyEmployed, noticePeriod
        case positionsAppliedFor, positionOther, preferredEmploymentType, earliestStartDate
        case expectedSalary, lastDrawnSalary, willingToWorkShifts, willingToTravel
        case hasOwnTransport, howDidYouHear, referrerName
        case declarationAccuracy, pdpaConsent, backgroundCheckConsent
        case hasMedicalCondition, medicalDetails, submissionDate, referenceNumber
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fullName = try container.decode(String.self, forKey: .fullName)
        preferredName = try container.decode(String.self, forKey: .preferredName)
        nricFIN = try container.decode(String.self, forKey: .nricFIN)
        dateOfBirth = try container.decode(Date.self, forKey: .dateOfBirth)
        gender = try container.decode(Gender.self, forKey: .gender)
        nationality = try container.decode(NationalityStatus.self, forKey: .nationality)
        race = try container.decode(Race.self, forKey: .race)
        raceOther = try container.decode(String.self, forKey: .raceOther)
        contactNumber = try container.decode(String.self, forKey: .contactNumber)
        emailAddress = try container.decode(String.self, forKey: .emailAddress)
        residentialAddress = try container.decode(String.self, forKey: .residentialAddress)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        emergencyContactName = try container.decode(String.self, forKey: .emergencyContactName)
        emergencyContactNumber = try container.decode(String.self, forKey: .emergencyContactNumber)
        emergencyContactRelationship = try container.decode(EmergencyRelationship.self, forKey: .emergencyContactRelationship)
        highestQualification = try container.decode(HighestQualification.self, forKey: .highestQualification)
        fieldOfStudy = try container.decode(String.self, forKey: .fieldOfStudy)
        institutionName = try container.decode(String.self, forKey: .institutionName)
        yearOfGraduation = try container.decode(Int.self, forKey: .yearOfGraduation)
        additionalQualifications = try container.decode([QualificationRecord].self, forKey: .additionalQualifications)
        professionalCertifications = try container.decode(String.self, forKey: .professionalCertifications)
        selectedLanguages = try container.decode([LanguageProficiency].self, forKey: .selectedLanguages)
        totalExperience = try container.decode(TotalExperience.self, forKey: .totalExperience)
        employmentHistory = try container.decode([EmploymentRecord].self, forKey: .employmentHistory)
        isCurrentlyEmployed = try container.decode(Bool.self, forKey: .isCurrentlyEmployed)
        noticePeriod = try container.decode(NoticePeriod.self, forKey: .noticePeriod)
        positionsAppliedFor = try container.decode(Set<Position>.self, forKey: .positionsAppliedFor)
        positionOther = try container.decode(String.self, forKey: .positionOther)
        preferredEmploymentType = try container.decode(EmploymentType.self, forKey: .preferredEmploymentType)
        earliestStartDate = try container.decode(Date.self, forKey: .earliestStartDate)
        expectedSalary = try container.decode(String.self, forKey: .expectedSalary)
        lastDrawnSalary = try container.decode(String.self, forKey: .lastDrawnSalary)
        willingToWorkShifts = try container.decode(WillingnessOption.self, forKey: .willingToWorkShifts)
        willingToTravel = try container.decode(TravelOption.self, forKey: .willingToTravel)
        hasOwnTransport = try container.decode(Bool.self, forKey: .hasOwnTransport)
        howDidYouHear = try container.decode(HearAboutUs.self, forKey: .howDidYouHear)
        referrerName = try container.decode(String.self, forKey: .referrerName)
        declarationAccuracy = try container.decode(Bool.self, forKey: .declarationAccuracy)
        pdpaConsent = try container.decode(Bool.self, forKey: .pdpaConsent)
        backgroundCheckConsent = try container.decode(Bool.self, forKey: .backgroundCheckConsent)
        hasMedicalCondition = try container.decode(MedicalDeclaration.self, forKey: .hasMedicalCondition)
        medicalDetails = try container.decode(String.self, forKey: .medicalDetails)
        submissionDate = try container.decode(Date.self, forKey: .submissionDate)
        referenceNumber = try container.decode(String.self, forKey: .referenceNumber)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(preferredName, forKey: .preferredName)
        try container.encode(nricFIN, forKey: .nricFIN)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(gender, forKey: .gender)
        try container.encode(nationality, forKey: .nationality)
        try container.encode(race, forKey: .race)
        try container.encode(raceOther, forKey: .raceOther)
        try container.encode(contactNumber, forKey: .contactNumber)
        try container.encode(emailAddress, forKey: .emailAddress)
        try container.encode(residentialAddress, forKey: .residentialAddress)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(emergencyContactName, forKey: .emergencyContactName)
        try container.encode(emergencyContactNumber, forKey: .emergencyContactNumber)
        try container.encode(emergencyContactRelationship, forKey: .emergencyContactRelationship)
        try container.encode(highestQualification, forKey: .highestQualification)
        try container.encode(fieldOfStudy, forKey: .fieldOfStudy)
        try container.encode(institutionName, forKey: .institutionName)
        try container.encode(yearOfGraduation, forKey: .yearOfGraduation)
        try container.encode(additionalQualifications, forKey: .additionalQualifications)
        try container.encode(professionalCertifications, forKey: .professionalCertifications)
        try container.encode(selectedLanguages, forKey: .selectedLanguages)
        try container.encode(totalExperience, forKey: .totalExperience)
        try container.encode(employmentHistory, forKey: .employmentHistory)
        try container.encode(isCurrentlyEmployed, forKey: .isCurrentlyEmployed)
        try container.encode(noticePeriod, forKey: .noticePeriod)
        try container.encode(positionsAppliedFor, forKey: .positionsAppliedFor)
        try container.encode(positionOther, forKey: .positionOther)
        try container.encode(preferredEmploymentType, forKey: .preferredEmploymentType)
        try container.encode(earliestStartDate, forKey: .earliestStartDate)
        try container.encode(expectedSalary, forKey: .expectedSalary)
        try container.encode(lastDrawnSalary, forKey: .lastDrawnSalary)
        try container.encode(willingToWorkShifts, forKey: .willingToWorkShifts)
        try container.encode(willingToTravel, forKey: .willingToTravel)
        try container.encode(hasOwnTransport, forKey: .hasOwnTransport)
        try container.encode(howDidYouHear, forKey: .howDidYouHear)
        try container.encode(referrerName, forKey: .referrerName)
        try container.encode(declarationAccuracy, forKey: .declarationAccuracy)
        try container.encode(pdpaConsent, forKey: .pdpaConsent)
        try container.encode(backgroundCheckConsent, forKey: .backgroundCheckConsent)
        try container.encode(hasMedicalCondition, forKey: .hasMedicalCondition)
        try container.encode(medicalDetails, forKey: .medicalDetails)
        try container.encode(submissionDate, forKey: .submissionDate)
        try container.encode(referenceNumber, forKey: .referenceNumber)
    }

    func reset() {
        fullName = ""
        preferredName = ""
        nricFIN = ""
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        gender = .male
        nationality = .singaporeCitizen
        race = .chinese
        raceOther = ""
        contactNumber = ""
        emailAddress = ""
        residentialAddress = ""
        postalCode = ""
        emergencyContactName = ""
        emergencyContactNumber = ""
        emergencyContactRelationship = .parent
        highestQualification = .diploma
        fieldOfStudy = ""
        institutionName = ""
        yearOfGraduation = Calendar.current.component(.year, from: Date())
        additionalQualifications = []
        professionalCertifications = ""
        selectedLanguages = []
        totalExperience = .freshGraduate
        employmentHistory = []
        isCurrentlyEmployed = false
        noticePeriod = .immediate
        positionsAppliedFor = []
        positionOther = ""
        preferredEmploymentType = .fullTime
        earliestStartDate = Date()
        expectedSalary = ""
        lastDrawnSalary = ""
        willingToWorkShifts = .openToDiscussion
        willingToTravel = .occasionally
        hasOwnTransport = false
        howDidYouHear = .walkIn
        referrerName = ""
        declarationAccuracy = false
        pdpaConsent = false
        backgroundCheckConsent = false
        hasMedicalCondition = .no
        medicalDetails = ""
        signatureData = nil
        submissionDate = Date()
        referenceNumber = ""
    }
}

// MARK: - Enums

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case preferNotToSay = "Prefer not to say"
}

enum NationalityStatus: String, Codable, CaseIterable {
    case singaporeCitizen = "Singapore Citizen"
    case singaporePR = "Singapore PR"
    case employmentPass = "Employment Pass"
    case sPass = "S Pass"
    case workPermit = "Work Permit"
    case dependantsPass = "Dependant's Pass"
    case longTermVisitPass = "Long-Term Visit Pass"
    case others = "Others"
}

enum Race: String, Codable, CaseIterable {
    case chinese = "Chinese"
    case malay = "Malay"
    case indian = "Indian"
    case eurasian = "Eurasian"
    case others = "Others"
}

enum EmergencyRelationship: String, Codable, CaseIterable {
    case parent = "Parent"
    case spouse = "Spouse"
    case sibling = "Sibling"
    case friend = "Friend"
    case others = "Others"
}

enum HighestQualification: String, Codable, CaseIterable {
    case psle = "PSLE"
    case nLevel = "N-Level"
    case oLevel = "O-Level"
    case aLevel = "A-Level"
    case nitec = "Nitec / Higher Nitec"
    case diploma = "Diploma"
    case advancedDiploma = "Advanced Diploma"
    case bachelors = "Bachelor's Degree"
    case postgraduateDiploma = "Postgraduate Diploma"
    case masters = "Master's Degree"
    case doctorate = "Doctorate"
    case professional = "Professional Qualification"
    case others = "Others"
}

enum TotalExperience: String, Codable, CaseIterable {
    case freshGraduate = "Fresh Graduate"
    case lessThanOne = "<1 year"
    case oneToThree = "1-3 years"
    case threeToFive = "3-5 years"
    case fiveToTen = "5-10 years"
    case tenPlus = "10+ years"
}

enum NoticePeriod: String, Codable, CaseIterable {
    case immediate = "Immediate"
    case oneWeek = "1 week"
    case twoWeeks = "2 weeks"
    case oneMonth = "1 month"
    case twoMonths = "2 months"
    case threeMonths = "3 months"
}

enum Position: String, Codable, CaseIterable, Hashable {
    case flavorist = "Flavorist (R&D)"
    case labAnalyst = "Laboratory Analyst / Analytical Chemist"
    case qaQc = "Quality Assurance / Quality Control"
    case productionOperator = "Production Operator / Technician"
    case warehouseLogistics = "Warehouse & Logistics"
    case salesBD = "Sales & Business Development"
    case marketingComms = "Marketing & Communications"
    case financeAccounting = "Finance & Accounting"
    case humanResources = "Human Resources"
    case itSystems = "IT & Systems"
    case adminOffice = "Administrative / Office Support"
    case others = "Others"
}

enum EmploymentType: String, Codable, CaseIterable {
    case fullTime = "Full-Time"
    case partTime = "Part-Time"
    case contract = "Contract"
    case internship = "Internship"
}

enum WillingnessOption: String, Codable, CaseIterable {
    case yes = "Yes"
    case no = "No"
    case openToDiscussion = "Open to discussion"
}

enum TravelOption: String, Codable, CaseIterable {
    case yes = "Yes"
    case no = "No"
    case occasionally = "Occasionally"
}

enum HearAboutUs: String, Codable, CaseIterable {
    case companyWebsite = "Company Website"
    case jobStreet = "JobStreet"
    case linkedIn = "LinkedIn"
    case indeed = "Indeed"
    case myCareersFuture = "MyCareersFuture"
    case referral = "Referral"
    case walkIn = "Walk-in"
    case careerFair = "Career Fair"
    case others = "Others"
}

enum MedicalDeclaration: String, Codable, CaseIterable {
    case no = "No"
    case yes = "Yes"
}

enum AppScreen: Int, CaseIterable {
    case welcome = 0
    case personalDetails = 1
    case education = 2
    case workExperience = 3
    case positionAvailability = 4
    case declaration = 5
    case confirmation = 6
    case admin = 7

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .personalDetails: return "Personal Details"
        case .education: return "Education"
        case .workExperience: return "Experience"
        case .positionAvailability: return "Position"
        case .declaration: return "Declaration"
        case .confirmation: return "Confirmation"
        case .admin: return "Admin"
        }
    }

    static var formScreens: [AppScreen] {
        [.personalDetails, .education, .workExperience, .positionAvailability, .declaration]
    }
}
