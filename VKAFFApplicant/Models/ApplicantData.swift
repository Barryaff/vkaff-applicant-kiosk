import Foundation

class ApplicantData: ObservableObject, Codable {
    // MARK: - Personal Details
    @Published var fullName: String = ""
    @Published var preferredName: String = ""
    @Published var nricFIN: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var gender: Gender = .male
    @Published var nationality: Nationality = .singaporean
    @Published var nationalityOther: String = ""
    @Published var hasWorkedInSingapore: Bool = false
    @Published var race: Race = .chinese
    @Published var raceOther: String = ""
    @Published var contactCountryCode: String = "+65"
    @Published var contactNumber: String = ""
    @Published var emailAddress: String = ""
    @Published var residentialAddress: String = ""
    @Published var postalCode: String = ""
    @Published var passportNumber: String = ""
    @Published var drivingLicenseClass: String = ""
    @Published var emergencyContacts: [EmergencyContact] = [EmergencyContact()]

    // MARK: - Education & Qualifications
    @Published var highestQualification: HighestQualification = .diploma
    @Published var highestQualificationOther: String = ""
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

    // MARK: - References
    @Published var references: [ReferenceRecord] = []

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
    @Published var openToOtherPositions: Bool = true

    // MARK: - General Information
    @Published var previouslyApplied: Bool = false
    @Published var hasConnectionsAtAFF: Bool = false
    @Published var connectionsDetails: String = ""
    @Published var hasConflictOfInterest: Bool = false
    @Published var conflictDetails: String = ""
    @Published var hasBankruptcy: Bool = false
    @Published var bankruptcyDetails: String = ""
    @Published var hasLegalProceedings: Bool = false
    @Published var legalDetails: String = ""

    // MARK: - Declaration & Consent
    @Published var declarationAccuracy: Bool = false
    @Published var pdpaConsent: Bool = false
    @Published var hasMedicalCondition: MedicalDeclaration = .no
    @Published var medicalDetails: String = ""
    @Published var signatureData: Data? = nil
    @Published var submissionDate: Date = Date()

    // MARK: - Metadata
    @Published var referenceNumber: String = ""

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case fullName, preferredName, nricFIN, dateOfBirth, gender, nationality
        case nationalityOther, hasWorkedInSingapore
        case race, raceOther, contactCountryCode, contactNumber, emailAddress, residentialAddress, postalCode
        case passportNumber, drivingLicenseClass
        case emergencyContacts
        case highestQualification, highestQualificationOther, fieldOfStudy, institutionName, yearOfGraduation
        case additionalQualifications, professionalCertifications, selectedLanguages
        case totalExperience, employmentHistory, isCurrentlyEmployed, noticePeriod
        case references
        case positionsAppliedFor, positionOther, preferredEmploymentType, earliestStartDate
        case expectedSalary, lastDrawnSalary, willingToWorkShifts, willingToTravel
        case hasOwnTransport, howDidYouHear, referrerName, openToOtherPositions
        case previouslyApplied, hasConnectionsAtAFF, connectionsDetails
        case hasConflictOfInterest, conflictDetails
        case hasBankruptcy, bankruptcyDetails, hasLegalProceedings, legalDetails
        case declarationAccuracy, pdpaConsent
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
        nationality = try container.decode(Nationality.self, forKey: .nationality)
        nationalityOther = try container.decodeIfPresent(String.self, forKey: .nationalityOther) ?? ""
        hasWorkedInSingapore = try container.decodeIfPresent(Bool.self, forKey: .hasWorkedInSingapore) ?? false
        race = try container.decode(Race.self, forKey: .race)
        raceOther = try container.decode(String.self, forKey: .raceOther)
        contactCountryCode = try container.decodeIfPresent(String.self, forKey: .contactCountryCode) ?? "+65"
        contactNumber = try container.decode(String.self, forKey: .contactNumber)
        emailAddress = try container.decode(String.self, forKey: .emailAddress)
        residentialAddress = try container.decode(String.self, forKey: .residentialAddress)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        passportNumber = try container.decodeIfPresent(String.self, forKey: .passportNumber) ?? ""
        drivingLicenseClass = try container.decodeIfPresent(String.self, forKey: .drivingLicenseClass) ?? ""
        emergencyContacts = try container.decodeIfPresent([EmergencyContact].self, forKey: .emergencyContacts) ?? [EmergencyContact()]
        highestQualification = try container.decode(HighestQualification.self, forKey: .highestQualification)
        highestQualificationOther = try container.decodeIfPresent(String.self, forKey: .highestQualificationOther) ?? ""
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
        references = try container.decodeIfPresent([ReferenceRecord].self, forKey: .references) ?? []
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
        openToOtherPositions = try container.decodeIfPresent(Bool.self, forKey: .openToOtherPositions) ?? true
        previouslyApplied = try container.decodeIfPresent(Bool.self, forKey: .previouslyApplied) ?? false
        hasConnectionsAtAFF = try container.decodeIfPresent(Bool.self, forKey: .hasConnectionsAtAFF) ?? false
        connectionsDetails = try container.decodeIfPresent(String.self, forKey: .connectionsDetails) ?? ""
        hasConflictOfInterest = try container.decodeIfPresent(Bool.self, forKey: .hasConflictOfInterest) ?? false
        conflictDetails = try container.decodeIfPresent(String.self, forKey: .conflictDetails) ?? ""
        hasBankruptcy = try container.decodeIfPresent(Bool.self, forKey: .hasBankruptcy) ?? false
        bankruptcyDetails = try container.decodeIfPresent(String.self, forKey: .bankruptcyDetails) ?? ""
        hasLegalProceedings = try container.decodeIfPresent(Bool.self, forKey: .hasLegalProceedings) ?? false
        legalDetails = try container.decodeIfPresent(String.self, forKey: .legalDetails) ?? ""
        declarationAccuracy = try container.decode(Bool.self, forKey: .declarationAccuracy)
        pdpaConsent = try container.decode(Bool.self, forKey: .pdpaConsent)
        hasMedicalCondition = try container.decode(MedicalDeclaration.self, forKey: .hasMedicalCondition)
        medicalDetails = try container.decode(String.self, forKey: .medicalDetails)
        submissionDate = try container.decode(Date.self, forKey: .submissionDate)
        referenceNumber = try container.decode(String.self, forKey: .referenceNumber)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode with sanitized string values (trimmed, normalized)
        try container.encode(Validators.sanitizeInput(fullName), forKey: .fullName)
        try container.encode(Validators.sanitizeInput(preferredName), forKey: .preferredName)
        try container.encode(nricFIN.trimmingCharacters(in: .whitespaces).uppercased(), forKey: .nricFIN)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(gender, forKey: .gender)
        try container.encode(nationality, forKey: .nationality)
        try container.encode(Validators.sanitizeInput(nationalityOther), forKey: .nationalityOther)
        try container.encode(hasWorkedInSingapore, forKey: .hasWorkedInSingapore)
        try container.encode(race, forKey: .race)
        try container.encode(Validators.sanitizeInput(raceOther), forKey: .raceOther)
        try container.encode(contactCountryCode, forKey: .contactCountryCode)
        try container.encode(Validators.sanitizePhone(contactNumber), forKey: .contactNumber)
        try container.encode(emailAddress.trimmingCharacters(in: .whitespaces).lowercased(), forKey: .emailAddress)
        try container.encode(Validators.sanitizeInput(residentialAddress), forKey: .residentialAddress)
        try container.encode(Validators.sanitizePostalCode(postalCode), forKey: .postalCode)
        try container.encode(passportNumber.trimmingCharacters(in: .whitespaces).uppercased(), forKey: .passportNumber)
        try container.encode(Validators.sanitizeInput(drivingLicenseClass), forKey: .drivingLicenseClass)
        try container.encode(emergencyContacts, forKey: .emergencyContacts)
        try container.encode(highestQualification, forKey: .highestQualification)
        try container.encode(Validators.sanitizeInput(highestQualificationOther), forKey: .highestQualificationOther)
        try container.encode(Validators.sanitizeInput(fieldOfStudy), forKey: .fieldOfStudy)
        try container.encode(Validators.sanitizeInput(institutionName), forKey: .institutionName)
        try container.encode(yearOfGraduation, forKey: .yearOfGraduation)
        try container.encode(additionalQualifications, forKey: .additionalQualifications)
        try container.encode(Validators.sanitizeInput(professionalCertifications), forKey: .professionalCertifications)
        try container.encode(selectedLanguages, forKey: .selectedLanguages)
        try container.encode(totalExperience, forKey: .totalExperience)
        try container.encode(employmentHistory, forKey: .employmentHistory)
        try container.encode(isCurrentlyEmployed, forKey: .isCurrentlyEmployed)
        try container.encode(noticePeriod, forKey: .noticePeriod)
        try container.encode(references, forKey: .references)
        try container.encode(positionsAppliedFor, forKey: .positionsAppliedFor)
        try container.encode(Validators.sanitizeInput(positionOther), forKey: .positionOther)
        try container.encode(preferredEmploymentType, forKey: .preferredEmploymentType)
        try container.encode(earliestStartDate, forKey: .earliestStartDate)
        try container.encode(Validators.sanitizeInput(expectedSalary), forKey: .expectedSalary)
        try container.encode(Validators.sanitizeInput(lastDrawnSalary), forKey: .lastDrawnSalary)
        try container.encode(willingToWorkShifts, forKey: .willingToWorkShifts)
        try container.encode(willingToTravel, forKey: .willingToTravel)
        try container.encode(hasOwnTransport, forKey: .hasOwnTransport)
        try container.encode(howDidYouHear, forKey: .howDidYouHear)
        try container.encode(Validators.sanitizeInput(referrerName), forKey: .referrerName)
        try container.encode(openToOtherPositions, forKey: .openToOtherPositions)
        try container.encode(previouslyApplied, forKey: .previouslyApplied)
        try container.encode(hasConnectionsAtAFF, forKey: .hasConnectionsAtAFF)
        try container.encode(Validators.sanitizeInput(connectionsDetails), forKey: .connectionsDetails)
        try container.encode(hasConflictOfInterest, forKey: .hasConflictOfInterest)
        try container.encode(Validators.sanitizeInput(conflictDetails), forKey: .conflictDetails)
        try container.encode(hasBankruptcy, forKey: .hasBankruptcy)
        try container.encode(Validators.sanitizeInput(bankruptcyDetails), forKey: .bankruptcyDetails)
        try container.encode(hasLegalProceedings, forKey: .hasLegalProceedings)
        try container.encode(Validators.sanitizeInput(legalDetails), forKey: .legalDetails)
        try container.encode(declarationAccuracy, forKey: .declarationAccuracy)
        try container.encode(pdpaConsent, forKey: .pdpaConsent)
        try container.encode(hasMedicalCondition, forKey: .hasMedicalCondition)
        try container.encode(Validators.sanitizeInput(medicalDetails), forKey: .medicalDetails)
        try container.encode(submissionDate, forKey: .submissionDate)
        try container.encode(referenceNumber, forKey: .referenceNumber)
    }

    // MARK: - Sanitization

    /// Sanitizes all string fields in-place. Called before submission to normalize data.
    /// This modifies the object directly for use in PDF generation and other non-Codable outputs.
    func sanitizeAllFields() {
        fullName = Validators.sanitizeInput(fullName)
        preferredName = Validators.sanitizeInput(preferredName)
        nricFIN = nricFIN.trimmingCharacters(in: .whitespaces).uppercased()
        raceOther = Validators.sanitizeInput(raceOther)
        contactNumber = Validators.sanitizePhone(contactNumber)
        emailAddress = emailAddress.trimmingCharacters(in: .whitespaces).lowercased()
        residentialAddress = Validators.sanitizeInput(residentialAddress)
        postalCode = Validators.sanitizePostalCode(postalCode)
        passportNumber = passportNumber.trimmingCharacters(in: .whitespaces).uppercased()
        drivingLicenseClass = Validators.sanitizeInput(drivingLicenseClass)
        for i in emergencyContacts.indices {
            emergencyContacts[i].name = Validators.sanitizeInput(emergencyContacts[i].name)
            emergencyContacts[i].phoneNumber = Validators.sanitizePhone(emergencyContacts[i].phoneNumber)
            emergencyContacts[i].email = emergencyContacts[i].email.trimmingCharacters(in: .whitespaces).lowercased()
            emergencyContacts[i].address = Validators.sanitizeInput(emergencyContacts[i].address)
            emergencyContacts[i].relationshipOther = Validators.sanitizeInput(emergencyContacts[i].relationshipOther)
        }
        highestQualificationOther = Validators.sanitizeInput(highestQualificationOther)
        fieldOfStudy = Validators.sanitizeInput(fieldOfStudy)
        institutionName = Validators.sanitizeInput(institutionName)
        professionalCertifications = Validators.sanitizeInput(professionalCertifications)
        for i in employmentHistory.indices {
            employmentHistory[i].companyName = Validators.sanitizeInput(employmentHistory[i].companyName)
            employmentHistory[i].jobTitle = Validators.sanitizeInput(employmentHistory[i].jobTitle)
            employmentHistory[i].keyResponsibilities = Validators.sanitizeInput(employmentHistory[i].keyResponsibilities)
        }
        for i in references.indices {
            references[i].name = Validators.sanitizeInput(references[i].name)
            references[i].relationship = Validators.sanitizeInput(references[i].relationship)
            references[i].contactNumber = Validators.sanitizePhone(references[i].contactNumber)
            references[i].email = references[i].email.trimmingCharacters(in: .whitespaces).lowercased()
            references[i].yearsKnown = Validators.sanitizeInput(references[i].yearsKnown)
        }
        for i in additionalQualifications.indices {
            additionalQualifications[i].qualificationOther = Validators.sanitizeInput(additionalQualifications[i].qualificationOther)
            additionalQualifications[i].institution = Validators.sanitizeInput(additionalQualifications[i].institution)
        }
        for i in selectedLanguages.indices {
            selectedLanguages[i].customLanguage = Validators.sanitizeInput(selectedLanguages[i].customLanguage)
        }
        positionOther = Validators.sanitizeInput(positionOther)
        expectedSalary = Validators.sanitizeInput(expectedSalary)
        lastDrawnSalary = Validators.sanitizeInput(lastDrawnSalary)
        referrerName = Validators.sanitizeInput(referrerName)
        connectionsDetails = Validators.sanitizeInput(connectionsDetails)
        conflictDetails = Validators.sanitizeInput(conflictDetails)
        bankruptcyDetails = Validators.sanitizeInput(bankruptcyDetails)
        legalDetails = Validators.sanitizeInput(legalDetails)
        medicalDetails = Validators.sanitizeInput(medicalDetails)
    }

    func reset() {
        fullName = ""
        preferredName = ""
        nricFIN = ""
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        gender = .male
        nationality = .singaporean
        nationalityOther = ""
        hasWorkedInSingapore = false
        race = .chinese
        raceOther = ""
        contactCountryCode = "+65"
        contactNumber = ""
        emailAddress = ""
        residentialAddress = ""
        postalCode = ""
        passportNumber = ""
        drivingLicenseClass = ""
        emergencyContacts = [EmergencyContact()]
        highestQualification = .diploma
        highestQualificationOther = ""
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
        references = []
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
        openToOtherPositions = true
        previouslyApplied = false
        hasConnectionsAtAFF = false
        connectionsDetails = ""
        hasConflictOfInterest = false
        conflictDetails = ""
        hasBankruptcy = false
        bankruptcyDetails = ""
        hasLegalProceedings = false
        legalDetails = ""
        declarationAccuracy = false
        pdpaConsent = false
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

enum Nationality: String, Codable, CaseIterable {
    case singaporean = "Singaporean"
    case malaysian = "Malaysian"
    case indian = "Indian"
    case filipino = "Filipino"
    case indonesian = "Indonesian"
    case chinese = "Chinese"
    case bangladeshi = "Bangladeshi"
    case myanmar = "Myanmar"
    case vietnamese = "Vietnamese"
    case thai = "Thai"
    case sriLankan = "Sri Lankan"
    case pakistani = "Pakistani"
    case nepalese = "Nepalese"
    case japanese = "Japanese"
    case korean = "Korean"
    case australian = "Australian"
    case british = "British"
    case american = "American"
    case others = "Others"

    var isSingaporean: Bool {
        self == .singaporean
    }
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
    // Singapore
    case psle = "PSLE"
    case nLevel = "N-Level"
    case oLevel = "O-Level"
    case aLevel = "A-Level"
    case nitec = "Nitec / Higher Nitec"
    // Malaysia
    case upsr = "UPSR"
    case pt3 = "PT3"
    case spm = "SPM"
    case stpm = "STPM"
    case uec = "UEC"
    case skm = "Sijil Kemahiran Malaysia (SKM)"
    // International
    case primarySchool = "Primary / Elementary School"
    case secondarySchool = "Secondary / High School"
    case vocationalCertificate = "Vocational / Technical Certificate"
    // Common
    case diploma = "Diploma"
    case advancedDiploma = "Advanced Diploma"
    case bachelors = "Bachelor's Degree"
    case postgraduateDiploma = "Postgraduate Diploma"
    case masters = "Master's Degree"
    case doctorate = "Doctorate"
    case professional = "Professional Qualification"
    case others = "Others"

    static var singaporeOptions: [HighestQualification] {
        [.psle, .nLevel, .oLevel, .aLevel, .nitec,
         .diploma, .advancedDiploma, .bachelors, .postgraduateDiploma,
         .masters, .doctorate, .professional, .others]
    }

    static var malaysiaOptions: [HighestQualification] {
        [.upsr, .pt3, .spm, .stpm, .uec, .skm,
         .diploma, .advancedDiploma, .bachelors, .postgraduateDiploma,
         .masters, .doctorate, .professional, .others]
    }

    static var internationalOptions: [HighestQualification] {
        [.primarySchool, .secondarySchool, .vocationalCertificate,
         .diploma, .advancedDiploma, .bachelors, .postgraduateDiploma,
         .masters, .doctorate, .professional, .others]
    }

    static func options(for nationality: Nationality) -> [HighestQualification] {
        switch nationality {
        case .singaporean: return singaporeOptions
        case .malaysian: return malaysiaOptions
        default: return internationalOptions
        }
    }
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
