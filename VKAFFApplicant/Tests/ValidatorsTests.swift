import XCTest
@testable import VKAFFApplicant

final class ValidatorsTests: XCTestCase {

    // MARK: - NRIC Tests

    func testValidNRIC() {
        XCTAssertTrue(Validators.isValidNRIC("S1234567A"))
        XCTAssertTrue(Validators.isValidNRIC("T0123456Z"))
        XCTAssertTrue(Validators.isValidNRIC("F9876543B"))
        XCTAssertTrue(Validators.isValidNRIC("G1234567X"))
        XCTAssertTrue(Validators.isValidNRIC("M1234567K"))
    }

    func testInvalidNRIC() {
        XCTAssertFalse(Validators.isValidNRIC(""))
        XCTAssertFalse(Validators.isValidNRIC("A1234567B"))  // Wrong prefix
        XCTAssertFalse(Validators.isValidNRIC("S123456A"))   // Too few digits
        XCTAssertFalse(Validators.isValidNRIC("S12345678A")) // Too many digits
        XCTAssertFalse(Validators.isValidNRIC("S1234567"))   // Missing suffix
        XCTAssertFalse(Validators.isValidNRIC("1234567A"))   // Missing prefix
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
}
