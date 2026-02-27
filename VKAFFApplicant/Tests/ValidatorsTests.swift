import XCTest
@testable import VKAFFApplicant

final class ValidatorsTests: XCTestCase {

    // MARK: - NRIC Tests

    func testValidNRIC() {
        // Known valid NRICs (checksum verified)
        XCTAssertTrue(Validators.isValidNRIC("S0000001I"))
        XCTAssertTrue(Validators.isValidNRIC("S0000002G"))
        XCTAssertTrue(Validators.isValidNRIC("T0000001F"))
        XCTAssertTrue(Validators.isValidNRIC("F0000001R"))
        XCTAssertTrue(Validators.isValidNRIC("G0000001R"))
    }

    func testNRICWithLowercaseLetters() {
        // Validator uppercases internally, so lowercase should still validate
        XCTAssertTrue(Validators.isValidNRIC("s0000001i"))
        XCTAssertTrue(Validators.isValidNRIC("t0000001f"))
    }

    func testNRICWithSpaces() {
        // Validator trims whitespace, so padded input should still validate
        XCTAssertTrue(Validators.isValidNRIC("  S0000001I  "))
        XCTAssertTrue(Validators.isValidNRIC(" T0000001F"))
    }

    func testNRICWithMixedCaseAndSpaces() {
        XCTAssertTrue(Validators.isValidNRIC("  s0000001i  "))
    }

    func testNRICWrongChecksumLetter() {
        // S0000001I is valid; S0000001A should fail checksum
        XCTAssertFalse(Validators.isValidNRIC("S0000001A"))
        XCTAssertFalse(Validators.isValidNRIC("T0000001A"))
    }

    func testInvalidNRIC() {
        XCTAssertFalse(Validators.isValidNRIC(""))
        XCTAssertFalse(Validators.isValidNRIC("A1234567B"))  // Wrong prefix
        XCTAssertFalse(Validators.isValidNRIC("S123456A"))   // Too few digits
        XCTAssertFalse(Validators.isValidNRIC("S12345678A")) // Too many digits
        XCTAssertFalse(Validators.isValidNRIC("S1234567"))   // Missing suffix
        XCTAssertFalse(Validators.isValidNRIC("1234567A"))   // Missing prefix
    }

    func testNRICWithSpecialCharacters() {
        XCTAssertFalse(Validators.isValidNRIC("S1234567@"))
        XCTAssertFalse(Validators.isValidNRIC("S12345$7A"))
        XCTAssertFalse(Validators.isValidNRIC("S1234 567A"))
    }

    func testNRICFormatOnly() {
        // Format-only validation (no checksum check)
        XCTAssertTrue(Validators.isValidNRICFormat("S1234567B"))  // Wrong checksum but valid format
        XCTAssertFalse(Validators.isValidNRICFormat("X1234567A")) // Wrong prefix
        XCTAssertFalse(Validators.isValidNRICFormat("S123456A"))  // Too few digits
        XCTAssertTrue(Validators.isValidNRICFormat("  s1234567a  "))  // Trimmed + uppercased
    }

    // MARK: - Email Tests

    func testValidEmail() {
        XCTAssertTrue(Validators.isValidEmail("test@example.com"))
        XCTAssertTrue(Validators.isValidEmail("user.name@domain.co.sg"))
        XCTAssertTrue(Validators.isValidEmail("a@b.cd"))
    }

    func testInvalidEmail() {
        XCTAssertFalse(Validators.isValidEmail(""))
        XCTAssertFalse(Validators.isValidEmail("notanemail"))
        XCTAssertFalse(Validators.isValidEmail("@nodomain.com"))
        XCTAssertFalse(Validators.isValidEmail("missing@.com"))
    }

    func testEmailWithSpecialCharacters() {
        XCTAssertTrue(Validators.isValidEmail("user+tag@example.com"))
        XCTAssertTrue(Validators.isValidEmail("first.last@example.com"))
        XCTAssertTrue(Validators.isValidEmail("user%name@example.com"))
        XCTAssertTrue(Validators.isValidEmail("user_name@example.com"))
        XCTAssertTrue(Validators.isValidEmail("user-name@example.com"))
    }

    func testEmailWithConsecutiveDots() {
        XCTAssertFalse(Validators.isValidEmail("user..name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@example..com"))
    }

    func testEmailWithLeadingTrailingDots() {
        XCTAssertFalse(Validators.isValidEmail(".user@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user.@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@.example.com"))
    }

    func testEmailWithDomainHyphen() {
        XCTAssertFalse(Validators.isValidEmail("user@-example.com"))
    }

    func testEmailWithSubdomains() {
        XCTAssertTrue(Validators.isValidEmail("user@sub.domain.example.com"))
        XCTAssertTrue(Validators.isValidEmail("user@a.b.c.d.com"))
    }

    func testEmailWithMultipleAtSigns() {
        XCTAssertFalse(Validators.isValidEmail("user@@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@name@example.com"))
    }

    func testEmailWithSpaces() {
        XCTAssertTrue(Validators.isValidEmail("  test@example.com  "))
        XCTAssertFalse(Validators.isValidEmail("user name@example.com"))
    }

    func testEmailWithShortTLD() {
        XCTAssertFalse(Validators.isValidEmail("user@example.c"))
    }

    // MARK: - Phone Tests

    func testValidPhone() {
        XCTAssertTrue(Validators.isValidPhone("91234567"))
        XCTAssertTrue(Validators.isValidPhone("+6591234567"))
        XCTAssertTrue(Validators.isValidPhone("6591234567"))
    }

    func testInvalidPhone() {
        XCTAssertFalse(Validators.isValidPhone(""))
        XCTAssertFalse(Validators.isValidPhone("123"))
    }

    func testPhoneWithDashes() {
        XCTAssertTrue(Validators.isValidPhone("9123-4567"))
        XCTAssertTrue(Validators.isValidPhone("+65-9123-4567"))
    }

    func testPhoneWithSpaces() {
        XCTAssertTrue(Validators.isValidPhone("9123 4567"))
        XCTAssertTrue(Validators.isValidPhone("+65 9123 4567"))
    }

    func testPhoneStartingWith6() {
        XCTAssertTrue(Validators.isValidPhone("61234567"))
        XCTAssertTrue(Validators.isValidPhone("+6561234567"))
    }

    func testPhoneStartingWith8() {
        XCTAssertTrue(Validators.isValidPhone("81234567"))
    }

    func testPhoneInternationalVariousDigits() {
        // International validator accepts 7-15 digits regardless of first digit
        XCTAssertTrue(Validators.isValidPhone("11234567"))
        XCTAssertTrue(Validators.isValidPhone("21234567"))
        XCTAssertTrue(Validators.isValidPhone("31234567"))
        XCTAssertTrue(Validators.isValidPhone("41234567"))
        XCTAssertTrue(Validators.isValidPhone("51234567"))
        XCTAssertTrue(Validators.isValidPhone("71234567"))
    }

    func testPhoneTooShort() {
        XCTAssertFalse(Validators.isValidPhone("123456"))    // 6 digits — below minimum of 7
    }

    func testPhoneTooLong() {
        XCTAssertFalse(Validators.isValidPhone("1234567890123456"))  // 16 digits — above maximum of 15
    }

    func testPhoneBoundaryLengths() {
        XCTAssertTrue(Validators.isValidPhone("1234567"))              // 7 digits — minimum valid
        XCTAssertTrue(Validators.isValidPhone("123456789012345"))      // 15 digits — maximum valid
    }

    // MARK: - Postal Code Tests

    func testValidPostalCode() {
        XCTAssertTrue(Validators.isValidPostalCode("408832"))
        XCTAssertTrue(Validators.isValidPostalCode("123456"))
    }

    func testInvalidPostalCode() {
        XCTAssertFalse(Validators.isValidPostalCode(""))
        XCTAssertFalse(Validators.isValidPostalCode("12345"))
        XCTAssertFalse(Validators.isValidPostalCode("1234567"))
    }

    func testPostalCodeDistrictRange() {
        // District 00 is invalid (must be 01-82)
        XCTAssertFalse(Validators.isValidPostalCode("001234"))
        // District 83+ is invalid
        XCTAssertFalse(Validators.isValidPostalCode("831234"))
        XCTAssertFalse(Validators.isValidPostalCode("991234"))
        // District 82 is valid (upper boundary)
        XCTAssertTrue(Validators.isValidPostalCode("820000"))
        // District 01 is valid (lower boundary)
        XCTAssertTrue(Validators.isValidPostalCode("010000"))
    }

    // MARK: - isNotEmpty Tests

    func testIsNotEmpty() {
        XCTAssertTrue(Validators.isNotEmpty("hello"))
        XCTAssertFalse(Validators.isNotEmpty(""))
        XCTAssertFalse(Validators.isNotEmpty("   "))
        XCTAssertFalse(Validators.isNotEmpty("\n\t"))
    }

    // MARK: - Sanitization Tests

    func testSanitizeInputTrimsWhitespace() {
        XCTAssertEqual(Validators.sanitizeInput("  hello  "), "hello")
    }

    func testSanitizeInputCollapsesSpaces() {
        XCTAssertEqual(Validators.sanitizeInput("hello   world"), "hello world")
    }

    func testSanitizeInputEmptyString() {
        XCTAssertEqual(Validators.sanitizeInput(""), "")
    }

    func testSanitizePhoneAddsCountryCode() {
        XCTAssertEqual(Validators.sanitizePhone("91234567"), "+6591234567")
    }

    func testSanitizePhoneStripsFormatting() {
        XCTAssertEqual(Validators.sanitizePhone("9123-4567"), "+6591234567")
        XCTAssertEqual(Validators.sanitizePhone("9123 4567"), "+6591234567")
    }

    func testSanitizePhoneKeepsExistingCountryCode() {
        XCTAssertEqual(Validators.sanitizePhone("+6591234567"), "+6591234567")
    }

    func testSanitizePhoneAddsPlusTo65Prefix() {
        XCTAssertEqual(Validators.sanitizePhone("6591234567"), "+6591234567")
    }

    func testSanitizePostalCodeStripsNonDigits() {
        XCTAssertEqual(Validators.sanitizePostalCode("40 88 32"), "408832")
        XCTAssertEqual(Validators.sanitizePostalCode("40-8832"), "408832")
    }
}
