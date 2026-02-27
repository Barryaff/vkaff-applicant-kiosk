import XCTest
@testable import VKAFFApplicant

@MainActor
final class ApplicantDataTests: XCTestCase {

    // MARK: - Reset Tests

    func testResetClearsAllStringFieldsToEmpty() {
        var data = ApplicantData()
        data.fullName = "John Doe"
        data.preferredName = "Johnny"
        data.nricFIN = "S1234567A"
        data.contactNumber = "91234567"
        data.emailAddress = "john@example.com"
        data.residentialAddress = "123 Main St"
        data.postalCode = "408832"
        data.nationalityOther = "Brazilian"
        data.raceOther = "Eurasian"
        data.contactCountryCode = "+1"
        data.passportNumber = "E12345678"
        data.drivingLicenseClass = "Class 3"
        data.highestQualificationOther = "Trade Certificate"
        data.fieldOfStudy = "Chemistry"
        data.institutionName = "NUS"
        data.professionalCertifications = "FSSC 22000"
        data.positionOther = "Manager"
        data.expectedSalary = "5000"
        data.referrerName = "Bob"
        data.connectionsDetails = "John - cousin"
        data.conflictDetails = "Some conflict"
        data.bankruptcyDetails = "Some details"
        data.legalDetails = "Some proceedings"
        data.medicalDetails = "None"
        data.referenceNumber = "AFF-20260226-0001"

        data.reset()

        XCTAssertEqual(data.fullName, "")
        XCTAssertEqual(data.preferredName, "")
        XCTAssertEqual(data.nricFIN, "")
        XCTAssertEqual(data.contactNumber, "")
        XCTAssertEqual(data.emailAddress, "")
        XCTAssertEqual(data.residentialAddress, "")
        XCTAssertEqual(data.postalCode, "")
        XCTAssertEqual(data.nationalityOther, "")
        XCTAssertEqual(data.raceOther, "")
        XCTAssertEqual(data.contactCountryCode, "+65")
        XCTAssertEqual(data.passportNumber, "")
        XCTAssertEqual(data.drivingLicenseClass, "")
        XCTAssertEqual(data.highestQualificationOther, "")
        XCTAssertEqual(data.fieldOfStudy, "")
        XCTAssertEqual(data.institutionName, "")
        XCTAssertEqual(data.professionalCertifications, "")
        XCTAssertEqual(data.positionOther, "")
        XCTAssertEqual(data.expectedSalary, "")
        XCTAssertEqual(data.referrerName, "")
        XCTAssertEqual(data.connectionsDetails, "")
        XCTAssertEqual(data.conflictDetails, "")
        XCTAssertEqual(data.bankruptcyDetails, "")
        XCTAssertEqual(data.legalDetails, "")
        XCTAssertEqual(data.medicalDetails, "")
        XCTAssertEqual(data.referenceNumber, "")
    }

    func testResetClearsBoolFieldsToDefaults() {
        var data = ApplicantData()
        data.isCurrentlyEmployed = true
        data.declarationAccuracy = true
        data.pdpaConsent = true
        data.hasWorkedInSingapore = true
        data.openToOtherPositions = false
        data.previouslyApplied = true
        data.hasConnectionsAtAFF = true
        data.hasConflictOfInterest = true
        data.hasBankruptcy = true
        data.hasLegalProceedings = true

        data.reset()

        XCTAssertFalse(data.isCurrentlyEmployed)
        XCTAssertFalse(data.declarationAccuracy)
        XCTAssertFalse(data.pdpaConsent)
        XCTAssertFalse(data.hasWorkedInSingapore)
        XCTAssertTrue(data.openToOtherPositions)
        XCTAssertFalse(data.previouslyApplied)
        XCTAssertFalse(data.hasConnectionsAtAFF)
        XCTAssertFalse(data.hasConflictOfInterest)
        XCTAssertFalse(data.hasBankruptcy)
        XCTAssertFalse(data.hasLegalProceedings)
    }

    func testResetClearsEnumFieldsToDefaults() {
        var data = ApplicantData()
        data.gender = .female
        data.nationality = .filipino
        data.race = .malay
        data.highestQualification = .masters
        data.totalExperience = .tenPlus
        data.noticePeriod = .threeMonths
        data.preferredEmploymentType = .contract
        data.willingToWorkShifts = .yes
        data.willingToTravel = .yes
        data.howDidYouHear = .linkedIn
        data.hasMedicalCondition = .yes

        data.reset()

        XCTAssertEqual(data.gender, .male)
        XCTAssertEqual(data.nationality, .singaporean)
        XCTAssertEqual(data.race, .chinese)
        XCTAssertEqual(data.highestQualification, .diploma)
        XCTAssertEqual(data.totalExperience, .freshGraduate)
        XCTAssertEqual(data.noticePeriod, .immediate)
        XCTAssertEqual(data.preferredEmploymentType, .fullTime)
        XCTAssertEqual(data.willingToWorkShifts, .openToDiscussion)
        XCTAssertEqual(data.willingToTravel, .occasionally)
        XCTAssertEqual(data.howDidYouHear, .walkIn)
        XCTAssertEqual(data.hasMedicalCondition, .no)
    }

    func testResetClearsArrayFields() {
        var data = ApplicantData()
        data.additionalQualifications = [QualificationRecord()]
        data.selectedLanguages = [LanguageProficiency()]
        data.employmentHistory = [EmploymentRecord()]
        data.references = [ReferenceRecord()]
        data.positionsAppliedFor = [.flavorist, .labAnalyst]

        data.reset()

        XCTAssertTrue(data.additionalQualifications.isEmpty)
        XCTAssertTrue(data.selectedLanguages.isEmpty)
        XCTAssertTrue(data.employmentHistory.isEmpty)
        XCTAssertTrue(data.references.isEmpty)
        XCTAssertTrue(data.positionsAppliedFor.isEmpty)
    }

    func testResetClearsEmergencyContactsToDefault() {
        var data = ApplicantData()
        data.emergencyContacts = [
            EmergencyContact(name: "Jane", phoneNumber: "81234567", relationship: .spouse),
            EmergencyContact(name: "Bob", phoneNumber: "91234567", relationship: .friend)
        ]

        data.reset()

        XCTAssertEqual(data.emergencyContacts.count, 1)
        XCTAssertEqual(data.emergencyContacts[0].name, "")
        XCTAssertEqual(data.emergencyContacts[0].phoneNumber, "")
        XCTAssertEqual(data.emergencyContacts[0].relationship, .parent)
    }

    func testResetClearsSignatureData() {
        var data = ApplicantData()
        data.signatureData = Data([0x00, 0x01, 0x02])

        data.reset()

        XCTAssertNil(data.signatureData)
    }

    func testResetSetsYearOfGraduationToCurrentYear() {
        var data = ApplicantData()
        data.yearOfGraduation = 1990

        data.reset()

        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(data.yearOfGraduation, currentYear)
    }

    // MARK: - Codable Round-Trip Tests

    func testCodableRoundTripDefaultValues() {
        let original = ApplicantData()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(original) else {
            XCTFail("Failed to encode ApplicantData")
            return
        }

        guard let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed to decode ApplicantData")
            return
        }

        XCTAssertEqual(decoded.fullName, original.fullName)
        XCTAssertEqual(decoded.preferredName, original.preferredName)
        XCTAssertEqual(decoded.nricFIN, original.nricFIN)
        XCTAssertEqual(decoded.gender, original.gender)
        XCTAssertEqual(decoded.nationality, original.nationality)
        XCTAssertEqual(decoded.nationalityOther, original.nationalityOther)
        XCTAssertEqual(decoded.hasWorkedInSingapore, original.hasWorkedInSingapore)
        XCTAssertEqual(decoded.race, original.race)
        XCTAssertEqual(decoded.raceOther, original.raceOther)
        XCTAssertEqual(decoded.contactCountryCode, original.contactCountryCode)
        XCTAssertEqual(decoded.contactNumber, original.contactNumber)
        XCTAssertEqual(decoded.emailAddress, original.emailAddress)
        XCTAssertEqual(decoded.residentialAddress, original.residentialAddress)
        XCTAssertEqual(decoded.postalCode, original.postalCode)
        XCTAssertEqual(decoded.passportNumber, original.passportNumber)
        XCTAssertEqual(decoded.drivingLicenseClass, original.drivingLicenseClass)
        XCTAssertEqual(decoded.emergencyContacts.count, original.emergencyContacts.count)
        XCTAssertEqual(decoded.highestQualification, original.highestQualification)
        XCTAssertEqual(decoded.highestQualificationOther, original.highestQualificationOther)
        XCTAssertEqual(decoded.fieldOfStudy, original.fieldOfStudy)
        XCTAssertEqual(decoded.institutionName, original.institutionName)
        XCTAssertEqual(decoded.yearOfGraduation, original.yearOfGraduation)
        XCTAssertEqual(decoded.professionalCertifications, original.professionalCertifications)
        XCTAssertEqual(decoded.totalExperience, original.totalExperience)
        XCTAssertEqual(decoded.isCurrentlyEmployed, original.isCurrentlyEmployed)
        XCTAssertEqual(decoded.noticePeriod, original.noticePeriod)
        XCTAssertEqual(decoded.positionsAppliedFor, original.positionsAppliedFor)
        XCTAssertEqual(decoded.positionOther, original.positionOther)
        XCTAssertEqual(decoded.preferredEmploymentType, original.preferredEmploymentType)
        XCTAssertEqual(decoded.expectedSalary, original.expectedSalary)
        XCTAssertEqual(decoded.willingToWorkShifts, original.willingToWorkShifts)
        XCTAssertEqual(decoded.willingToTravel, original.willingToTravel)
        XCTAssertEqual(decoded.howDidYouHear, original.howDidYouHear)
        XCTAssertEqual(decoded.referrerName, original.referrerName)
        XCTAssertEqual(decoded.openToOtherPositions, original.openToOtherPositions)
        XCTAssertEqual(decoded.previouslyApplied, original.previouslyApplied)
        XCTAssertEqual(decoded.hasConnectionsAtAFF, original.hasConnectionsAtAFF)
        XCTAssertEqual(decoded.connectionsDetails, original.connectionsDetails)
        XCTAssertEqual(decoded.hasConflictOfInterest, original.hasConflictOfInterest)
        XCTAssertEqual(decoded.conflictDetails, original.conflictDetails)
        XCTAssertEqual(decoded.hasBankruptcy, original.hasBankruptcy)
        XCTAssertEqual(decoded.bankruptcyDetails, original.bankruptcyDetails)
        XCTAssertEqual(decoded.hasLegalProceedings, original.hasLegalProceedings)
        XCTAssertEqual(decoded.legalDetails, original.legalDetails)
        XCTAssertEqual(decoded.declarationAccuracy, original.declarationAccuracy)
        XCTAssertEqual(decoded.pdpaConsent, original.pdpaConsent)
        XCTAssertEqual(decoded.hasMedicalCondition, original.hasMedicalCondition)
        XCTAssertEqual(decoded.medicalDetails, original.medicalDetails)
        XCTAssertEqual(decoded.referenceNumber, original.referenceNumber)
    }

    func testCodableRoundTripWithPopulatedValues() {
        var original = ApplicantData()
        original.fullName = "Test User"
        original.preferredName = "Testy"
        original.nricFIN = "S1234567A"
        original.gender = .female
        original.nationality = .malaysian
        original.nationalityOther = ""
        original.hasWorkedInSingapore = true
        original.race = .indian
        original.raceOther = ""
        original.contactCountryCode = "+60"
        original.contactNumber = "+6591234567"
        original.emailAddress = "test@example.com"
        original.residentialAddress = "123 Test Road"
        original.postalCode = "408832"
        original.passportNumber = "A12345678"
        original.drivingLicenseClass = "Class 3"
        original.highestQualification = .bachelors
        original.highestQualificationOther = ""
        original.fieldOfStudy = "Computer Science"
        original.institutionName = "NTU"
        original.yearOfGraduation = 2020
        original.professionalCertifications = "AWS Certified"
        original.totalExperience = .threeToFive
        original.isCurrentlyEmployed = true
        original.noticePeriod = .oneMonth
        original.positionsAppliedFor = [.itSystems, .others]
        original.positionOther = "DevOps"
        original.preferredEmploymentType = .fullTime
        original.expectedSalary = "6000"
        original.willingToWorkShifts = .yes
        original.willingToTravel = .occasionally
        original.howDidYouHear = .linkedIn
        original.referrerName = "Friend"
        original.openToOtherPositions = false
        original.previouslyApplied = true
        original.hasConnectionsAtAFF = true
        original.connectionsDetails = "John - cousin"
        original.hasConflictOfInterest = false
        original.conflictDetails = ""
        original.hasBankruptcy = false
        original.bankruptcyDetails = ""
        original.hasLegalProceedings = false
        original.legalDetails = ""
        original.declarationAccuracy = true
        original.pdpaConsent = true
        original.hasMedicalCondition = .no
        original.medicalDetails = ""
        original.referenceNumber = "AFF-20260226-0001"

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(original) else {
            XCTFail("Failed to encode populated ApplicantData")
            return
        }

        guard let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed to decode populated ApplicantData")
            return
        }

        XCTAssertEqual(decoded.fullName, "Test User")
        XCTAssertEqual(decoded.preferredName, "Testy")
        XCTAssertEqual(decoded.nricFIN, "S1234567A")
        XCTAssertEqual(decoded.gender, .female)
        XCTAssertEqual(decoded.nationality, .malaysian)
        XCTAssertEqual(decoded.hasWorkedInSingapore, true)
        XCTAssertEqual(decoded.race, .indian)
        XCTAssertEqual(decoded.contactCountryCode, "+60")
        XCTAssertEqual(decoded.contactNumber, "+6591234567")
        XCTAssertEqual(decoded.emailAddress, "test@example.com")
        XCTAssertEqual(decoded.residentialAddress, "123 Test Road")
        XCTAssertEqual(decoded.postalCode, "408832")
        XCTAssertEqual(decoded.passportNumber, "A12345678")
        XCTAssertEqual(decoded.drivingLicenseClass, "Class 3")
        XCTAssertEqual(decoded.highestQualification, .bachelors)
        XCTAssertEqual(decoded.fieldOfStudy, "Computer Science")
        XCTAssertEqual(decoded.institutionName, "NTU")
        XCTAssertEqual(decoded.yearOfGraduation, 2020)
        XCTAssertEqual(decoded.professionalCertifications, "AWS Certified")
        XCTAssertEqual(decoded.totalExperience, .threeToFive)
        XCTAssertEqual(decoded.isCurrentlyEmployed, true)
        XCTAssertEqual(decoded.noticePeriod, .oneMonth)
        XCTAssertEqual(decoded.positionsAppliedFor, [.itSystems, .others])
        XCTAssertEqual(decoded.positionOther, "DevOps")
        XCTAssertEqual(decoded.preferredEmploymentType, .fullTime)
        XCTAssertEqual(decoded.expectedSalary, "6000")
        XCTAssertEqual(decoded.willingToWorkShifts, .yes)
        XCTAssertEqual(decoded.willingToTravel, .occasionally)
        XCTAssertEqual(decoded.howDidYouHear, .linkedIn)
        XCTAssertEqual(decoded.referrerName, "Friend")
        XCTAssertEqual(decoded.openToOtherPositions, false)
        XCTAssertEqual(decoded.previouslyApplied, true)
        XCTAssertEqual(decoded.hasConnectionsAtAFF, true)
        XCTAssertEqual(decoded.connectionsDetails, "John - cousin")
        XCTAssertEqual(decoded.declarationAccuracy, true)
        XCTAssertEqual(decoded.pdpaConsent, true)
        XCTAssertEqual(decoded.hasMedicalCondition, .no)
        XCTAssertEqual(decoded.medicalDetails, "")
        XCTAssertEqual(decoded.referenceNumber, "AFF-20260226-0001")
    }

    // MARK: - Encoding Includes All Fields

    func testEncodingIncludesAllCodingKeys() {
        let data = ApplicantData()
        let encoder = JSONEncoder()

        guard let encoded = try? encoder.encode(data),
              let json = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            XCTFail("Failed to encode ApplicantData to JSON dictionary")
            return
        }

        let expectedKeys: [String] = [
            "fullName", "preferredName", "nricFIN", "dateOfBirth", "gender", "nationality",
            "nationalityOther", "hasWorkedInSingapore",
            "race", "raceOther", "contactCountryCode", "contactNumber", "emailAddress",
            "residentialAddress", "postalCode", "passportNumber", "drivingLicenseClass",
            "emergencyContacts",
            "highestQualification", "highestQualificationOther", "fieldOfStudy", "institutionName",
            "yearOfGraduation", "additionalQualifications", "professionalCertifications", "selectedLanguages",
            "totalExperience", "employmentHistory", "isCurrentlyEmployed", "noticePeriod",
            "references",
            "positionsAppliedFor", "positionOther", "preferredEmploymentType", "earliestStartDate",
            "expectedSalary", "willingToWorkShifts", "willingToTravel",
            "howDidYouHear", "referrerName", "openToOtherPositions",
            "previouslyApplied", "hasConnectionsAtAFF", "connectionsDetails",
            "hasConflictOfInterest", "conflictDetails",
            "hasBankruptcy", "bankruptcyDetails", "hasLegalProceedings", "legalDetails",
            "declarationAccuracy", "pdpaConsent",
            "hasMedicalCondition", "medicalDetails", "submissionDate", "referenceNumber"
        ]

        for key in expectedKeys {
            XCTAssertNotNil(json[key], "Encoded JSON is missing key: \(key)")
        }
    }

    func testEncodingKeyCountMatchesCodingKeysCount() {
        let data = ApplicantData()
        let encoder = JSONEncoder()

        guard let encoded = try? encoder.encode(data),
              let json = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            XCTFail("Failed to encode ApplicantData to JSON dictionary")
            return
        }

        // CodingKeys has 56 cases (signatureData, lastDrawnSalary, hasOwnTransport intentionally excluded)
        let expectedCount = 56
        XCTAssertEqual(json.keys.count, expectedCount,
                       "Encoded JSON should have \(expectedCount) keys, got \(json.keys.count). Keys: \(json.keys.sorted())")
    }

    // MARK: - Codable with Nested Types

    func testCodableRoundTripWithEmploymentHistory() {
        var data = ApplicantData()
        data.employmentHistory = [
            EmploymentRecord(
                companyName: "VKAFF",
                jobTitle: "Engineer",
                industry: .flavoursFragrances,
                isCurrentPosition: true,
                keyResponsibilities: "R&D"
            )
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(data),
              let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed Codable round-trip with employment history")
            return
        }

        XCTAssertEqual(decoded.employmentHistory.count, 1)
        XCTAssertEqual(decoded.employmentHistory.first?.companyName, "VKAFF")
        XCTAssertEqual(decoded.employmentHistory.first?.jobTitle, "Engineer")
        XCTAssertEqual(decoded.employmentHistory.first?.industry, .flavoursFragrances)
    }

    func testCodableRoundTripWithQualifications() {
        var data = ApplicantData()
        data.additionalQualifications = [
            QualificationRecord(qualification: .masters, institution: "NUS", year: 2022)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(data),
              let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed Codable round-trip with qualifications")
            return
        }

        XCTAssertEqual(decoded.additionalQualifications.count, 1)
        XCTAssertEqual(decoded.additionalQualifications.first?.qualification, .masters)
        XCTAssertEqual(decoded.additionalQualifications.first?.institution, "NUS")
    }

    func testCodableRoundTripWithLanguages() {
        var data = ApplicantData()
        data.selectedLanguages = [
            LanguageProficiency(language: .english, proficiency: .fluent),
            LanguageProficiency(language: .mandarin, proficiency: .native)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(data),
              let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed Codable round-trip with languages")
            return
        }

        XCTAssertEqual(decoded.selectedLanguages.count, 2)
        XCTAssertEqual(decoded.selectedLanguages[0].language, .english)
        XCTAssertEqual(decoded.selectedLanguages[0].proficiency, .fluent)
        XCTAssertEqual(decoded.selectedLanguages[1].language, .mandarin)
        XCTAssertEqual(decoded.selectedLanguages[1].proficiency, .native)
    }

    func testCodableRoundTripWithEmergencyContacts() {
        var data = ApplicantData()
        data.emergencyContacts = [
            EmergencyContact(name: "Jane Doe", phoneNumber: "81234567", relationship: .spouse),
            EmergencyContact(name: "Bob", phoneNumber: "91234567", relationship: .friend)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(data),
              let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed Codable round-trip with emergency contacts")
            return
        }

        XCTAssertEqual(decoded.emergencyContacts.count, 2)
        XCTAssertEqual(decoded.emergencyContacts[0].name, "Jane Doe")
        XCTAssertEqual(decoded.emergencyContacts[0].phoneNumber, "81234567")
        XCTAssertEqual(decoded.emergencyContacts[0].relationship, .spouse)
        XCTAssertEqual(decoded.emergencyContacts[1].name, "Bob")
        XCTAssertEqual(decoded.emergencyContacts[1].relationship, .friend)
    }

    func testCodableRoundTripWithReferences() {
        var data = ApplicantData()
        data.references = [
            ReferenceRecord(name: "Dr. Smith", relationship: "Former Supervisor", contactNumber: "91234567", email: "smith@example.com", yearsKnown: "5")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let encoded = try? encoder.encode(data),
              let decoded = try? decoder.decode(ApplicantData.self, from: encoded) else {
            XCTFail("Failed Codable round-trip with references")
            return
        }

        XCTAssertEqual(decoded.references.count, 1)
        XCTAssertEqual(decoded.references[0].name, "Dr. Smith")
        XCTAssertEqual(decoded.references[0].relationship, "Former Supervisor")
        XCTAssertEqual(decoded.references[0].email, "smith@example.com")
    }

    // MARK: - Default Initialization

    func testDefaultInitialization() {
        let data = ApplicantData()

        XCTAssertEqual(data.fullName, "")
        XCTAssertEqual(data.gender, .male)
        XCTAssertEqual(data.nationality, .singaporean)
        XCTAssertEqual(data.race, .chinese)
        XCTAssertFalse(data.isCurrentlyEmployed)
        XCTAssertTrue(data.positionsAppliedFor.isEmpty)
        XCTAssertTrue(data.employmentHistory.isEmpty)
        XCTAssertTrue(data.additionalQualifications.isEmpty)
        XCTAssertTrue(data.selectedLanguages.isEmpty)
        XCTAssertTrue(data.references.isEmpty)
        XCTAssertNil(data.signatureData)
        XCTAssertEqual(data.referenceNumber, "")
        XCTAssertEqual(data.emergencyContacts.count, 1)
        XCTAssertEqual(data.emergencyContacts[0].name, "")
        XCTAssertEqual(data.emergencyContacts[0].relationship, .parent)
        XCTAssertTrue(data.openToOtherPositions)
        XCTAssertFalse(data.previouslyApplied)
        XCTAssertFalse(data.hasConnectionsAtAFF)
        XCTAssertFalse(data.hasConflictOfInterest)
        XCTAssertFalse(data.hasBankruptcy)
        XCTAssertFalse(data.hasLegalProceedings)
    }
}
