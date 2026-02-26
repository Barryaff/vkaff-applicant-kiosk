import XCTest
@testable import VKAFFApplicant

final class NRICMaskerTests: XCTestCase {

    func testMaskStandardNRIC() {
        XCTAssertEqual(NRICMasker.mask("S1234567A"), "S••••567A")
    }

    func testMaskFIN() {
        XCTAssertEqual(NRICMasker.mask("G9876543Z"), "G••••543Z")
    }

    func testMaskLowercaseInput() {
        XCTAssertEqual(NRICMasker.mask("s1234567a"), "S••••567A")
    }

    func testMaskShortInput() {
        // Should return as-is if not 9 characters
        XCTAssertEqual(NRICMasker.mask("S123"), "S123")
    }

    func testMaskEmptyInput() {
        XCTAssertEqual(NRICMasker.mask(""), "")
    }

    func testUnmask() {
        let original = "S1234567A"
        XCTAssertEqual(NRICMasker.unmask(original), original)
    }
}
