import XCTest
@testable import VKAFFApplicant

@MainActor
final class ApplicantDataTests: XCTestCase {

    // MARK: - Reset Tests

    func testResetClearsAllStringFieldsToEmpty() {
        let data = ApplicantData()
        data.fullName = "John Doe"
        data.preferredName = "Johnny"
        data.nricFIN = "S1234567A"
        data.contactNumber = "91234567"
        data.emailAddress = "john@example.com"
        data.residentialAddress = "123 Main St"
        data.postalCode = "408832"
        data.emergencyContactName = "Jane"
        data.emergencyContactNumber = "81234567"
        data.fieldOfStudy = "Chemistry"
        data.institutionName = "NUS"
        data.professionalCertifications = "FSSC 22000"
        data.positionOther = "Manager"
        data.expectedSalary = "5000"
        data.lastDrawnSalary = "4000"
        data.referrerName = "Bob"
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
        XCTAssertEqual(data.emergencyContactName, "")
        XCTAssertEqual(data.emergencyContactNumber, "")
        XCTAssertEqual(data.fieldOfStudy, "")
        XCTAssertEqual(data.institutionName, "")
        XCTAssertEqual(data.professionalCertifications, "")
        XCTAssertEqual(data.positionOther, "")
        XCTAssertEqual(data.expectedSalary, "")
        XCTAssertEqual(data.lastDrawnSalary, "")
        XCTAssertEqual(data.referrerName, "")
        XCTAssertEqual(data.medicalDetails, "")
        XCTAssertEqual(data.referenceNumber, "")
    }

    func testResetClearsBoolFieldsToDefaults() {
        let data = ApplicantData()
        data.isCurrentlyEmployed = true
        data.declarationAccuracy = true
        data.pdpaConsent = true
        data.backgroundCheckConsent = true
        data.hasOwnTransport = true

        data.reset()

        XCTAssertFalse(data.isCurrentlyEmployed)
        XCTAssertFalse(data.declarationAccuracy)
        XCTAssertFalse(data.pdpaConsent)
        XCTAssertFalse(data.backgroundCheckConsent)
        XCTAssertFalse(data.hasOwnTransport)
    }

    func testResetClearsEnumFieldsToDefaults() {
        let data = ApplicantData()
        data.gender = .female
        data.nationality = .employmentPass
        data.race = .malay
        data.emergencyContactRelationship = .spouse
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
        XCTAssertEqual(data.nationality, .singaporeCitizen)
        XCTAssertEqual(data.race, .chinese)
        XCTAssertEqual(data.emergencyContactRelationship, .parent)
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
        let data = ApplicantData()
        data.additionalQualifications = [QualificationRecord()]
        data.selectedLanguages = [LanguageProficiency()]
        data.employmentHistory = [EmploymentRecord()]
        data.positionsAppliedFor = [.flavorist, .labAnalyst]

        data.reset()

        XCTAssertTrue(data.additionalQualifications.isEmpty)
        XCTAssertTrue(data.selectedLanguages.isEmpty)
        XCTAssertTrue(data.employmentHistory.isEmpty)
        XCTAssertTrue(data.positionsAppliedFor.isEmpty)
    }

    func testResetClearsSignatureData() {
        let data = ApplicantData()
        data.signatureData = Data([0x00, 0x01, 0x02])

        data.reset()

        XCTAssertNil(data.signatureData)
    }

    func testResetSetsYearOfGraduationToCurrentYear() {
        let data = ApplicantData()
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
        XCTAssertEqual(decoded.race, original.race)
        XCTAssertEqual(decoded.raceOther, original.raceOther)
        XCTAssertEqual(decoded.contactNumber, original.contactNumber)
        XCTAssertEqual(decoded.emailAddress, original.emailAddress)
        XCTAssertEqual(decoded.residentialAddress, original.residentialAddress)
        XCTAssertEqual(decoded.postalCode, original.postalCode)
        XCTAssertEqual(decoded.emergencyContactName, original.emergencyContactName)
        XCTAssertEqual(decoded.emergencyContactNumber, original.emergencyContactNumber)
        XCTAssertEqual(decoded.emergencyContactRelationship, original.emergencyContactRelationship)
        XCTAssertEqual(decoded.highestQualification, original.highestQualification)
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
        XCTAssertEqual(decoded.lastDrawnSalary, original.lastDrawnSalary)
        XCTAssertEqual(decoded.willingToWorkShifts, original.willingToWorkShifts)
        XCTAssertEqual(decoded.willingToTravel, original.willingToTravel)
        XCTAssertEqual(decoded.hasOwnTransport, original.hasOwnTransport)
        XCTAssertEqual(decoded.howDidYouHear, original.howDidYouHear)
        XCTAssertEqual(decoded.referrerName, original.referrerName)
        XCTAssertEqual(decoded.declarationAccuracy, original.declarationAccuracy)
        XCTAssertEqual(decoded.pdpaConsent, original.pdpaConsent)
        XCTAssertEqual(decoded.backgroundCheckConsent, original.backgroundCheckConsent)
        XCTAssertEqual(decoded.hasMedicalCondition, original.hasMedicalCondition)
        XCTAssertEqual(decoded.medicalDetails, original.medicalDetails)
        XCTAssertEqual(decoded.referenceNumber, original.referenceNumber)
    }

    func testCodableRoundTripWithPopulatedValues() {
        let original = ApplicantData()
        original.fullName = "Test User"
        original.preferredName = "Testy"
        original.nricFIN = "S1234567A"
        original.gender = .female
        original.nationality = .singaporePR
        original.race = .indian
        original.raceOther = ""
        original.contactNumber = "+6591234567"
        original.emailAddress = "test@example.com"
        original.residentialAddress = "123 Test Road"
        original.postalCode = "408832"
        original.emergencyContactName = "Emergency Person"
        original.emergencyContactNumber = "+6581234567"
        original.emergencyContactRelationship = .spouse
        original.highestQualification = .bachelors
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
        original.lastDrawnSalary = "5500"
        original.willingToWorkShifts = .yes
        original.willingToTravel = .occasionally
        original.hasOwnTransport = true
        original.howDidYouHear = .linkedIn
        original.referrerName = "Friend"
        original.declarationAccuracy = true
        original.pdpaConsent = true
        original.backgroundCheckConsent = true
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
        XCTAssertEqual(decoded.nationality, .singaporePR)
        XCTAssertEqual(decoded.race, .indian)
        XCTAssertEqual(decoded.contactNumber, "+6591234567")
        XCTAssertEqual(decoded.emailAddress, "test@example.com")
        XCTAssertEqual(decoded.residentialAddress, "123 Test Road")
        XCTAssertEqual(decoded.postalCode, "408832")
        XCTAssertEqual(decoded.emergencyContactName, "Emergency Person")
        XCTAssertEqual(decoded.emergencyContactNumber, "+6581234567")
        XCTAssertEqual(decoded.emergencyContactRelationship, .spouse)
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
        XCTAssertEqual(decoded.lastDrawnSalary, "5500")
        XCTAssertEqual(decoded.willingToWorkShifts, .yes)
        XCTAssertEqual(decoded.willingToTravel, .occasionally)
        XCTAssertEqual(decoded.hasOwnTransport, true)
        XCTAssertEqual(decoded.howDidYouHear, .linkedIn)
        XCTAssertEqual(decoded.referrerName, "Friend")
        XCTAssertEqual(decoded.declarationAccuracy, true)
        XCTAssertEqual(decoded.pdpaConsent, true)
        XCTAssertEqual(decoded.backgroundCheckConsent, true)
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

        // Verify every CodingKey case is present in the encoded JSON
        let expectedKeys: [String] = [
            "fullName", "preferredName", "nricFIN", "dateOfBirth", "gender", "nationality",
            "race", "raceOther", "contactNumber", "emailAddress", "residentialAddress", "postalCode",
            "emergencyContactName", "emergencyContactNumber", "emergencyContactRelationship",
            "highestQualification", "fieldOfStudy", "institutionName", "yearOfGraduation",
            "additionalQualifications", "professionalCertifications", "selectedLanguages",
            "totalExperience", "employmentHistory", "isCurrentlyEmployed", "noticePeriod",
            "positionsAppliedFor", "positionOther", "preferredEmploymentType", "earliestStartDate",
            "expectedSalary", "lastDrawnSalary", "willingToWorkShifts", "willingToTravel",
            "hasOwnTransport", "howDidYouHear", "referrerName",
            "declarationAccuracy", "pdpaConsent", "backgroundCheckConsent",
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

        // CodingKeys has 38 cases (count the enum cases)
        let expectedCount = 38
        XCTAssertEqual(json.keys.count, expectedCount,
                       "Encoded JSON should have \(expectedCount) keys, got \(json.keys.count). Keys: \(json.keys.sorted())")
    }

    // MARK: - Codable with Nested Types

    func testCodableRoundTripWithEmploymentHistory() {
        let data = ApplicantData()
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
        let data = ApplicantData()
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
        let data = ApplicantData()
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

    // MARK: - Default Initialization

    func testDefaultInitialization() {
        let data = ApplicantData()

        XCTAssertEqual(data.fullName, "")
        XCTAssertEqual(data.gender, .male)
        XCTAssertEqual(data.nationality, .singaporeCitizen)
        XCTAssertEqual(data.race, .chinese)
        XCTAssertFalse(data.isCurrentlyEmployed)
        XCTAssertTrue(data.positionsAppliedFor.isEmpty)
        XCTAssertTrue(data.employmentHistory.isEmpty)
        XCTAssertTrue(data.additionalQualifications.isEmpty)
        XCTAssertTrue(data.selectedLanguages.isEmpty)
        XCTAssertNil(data.signatureData)
        XCTAssertEqual(data.referenceNumber, "")
    }
}
