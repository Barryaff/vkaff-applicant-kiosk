import XCTest
@testable import VKAFFApplicant

final class NRICMaskerTests: XCTestCase {

    func testMaskStandardNRIC() {
        XCTAssertEqual(NRICMasker.mask("S1234567A"), "S\u{2022}\u{2022}\u{2022}\u{2022}567A")
    }

    func testMaskFIN() {
        XCTAssertEqual(NRICMasker.mask("G9876543Z"), "G\u{2022}\u{2022}\u{2022}\u{2022}543Z")
    }

    func testMaskLowercaseInput() {
        XCTAssertEqual(NRICMasker.mask("s1234567a"), "S\u{2022}\u{2022}\u{2022}\u{2022}567A")
    }

    func testMaskShortInput() {
        // Should return as-is (trimmed + uppercased) if not 9 characters
        XCTAssertEqual(NRICMasker.mask("S123"), "S123")
    }

    func testMaskEmptyInput() {
        XCTAssertEqual(NRICMasker.mask(""), "")
    }

    func testUnmask() {
        let original = "S1234567A"
        XCTAssertEqual(NRICMasker.unmask(original), original)
    }

    // MARK: - Whitespace Handling

    func testMaskWithLeadingWhitespace() {
        XCTAssertEqual(NRICMasker.mask("  S1234567A"), "S\u{2022}\u{2022}\u{2022}\u{2022}567A")
    }

    func testMaskWithTrailingWhitespace() {
        XCTAssertEqual(NRICMasker.mask("S1234567A  "), "S\u{2022}\u{2022}\u{2022}\u{2022}567A")
    }

    func testMaskWithSurroundingWhitespace() {
        XCTAssertEqual(NRICMasker.mask("  S1234567A  "), "S\u{2022}\u{2022}\u{2022}\u{2022}567A")
    }

    // MARK: - All Prefix Types

    func testMaskSPrefix() {
        let result = NRICMasker.mask("S1234567A")
        XCTAssertTrue(result.hasPrefix("S"))
    }

    func testMaskTPrefix() {
        let result = NRICMasker.mask("T0123456Z")
        XCTAssertTrue(result.hasPrefix("T"))
        XCTAssertEqual(result, "T\u{2022}\u{2022}\u{2022}\u{2022}456Z")
    }

    func testMaskFPrefix() {
        let result = NRICMasker.mask("F9876543B")
        XCTAssertTrue(result.hasPrefix("F"))
        XCTAssertEqual(result, "F\u{2022}\u{2022}\u{2022}\u{2022}543B")
    }

    func testMaskGPrefix() {
        let result = NRICMasker.mask("G1234567X")
        XCTAssertTrue(result.hasPrefix("G"))
        XCTAssertEqual(result, "G\u{2022}\u{2022}\u{2022}\u{2022}567X")
    }

    func testMaskMPrefix() {
        let result = NRICMasker.mask("M1234567K")
        XCTAssertTrue(result.hasPrefix("M"))
        XCTAssertEqual(result, "M\u{2022}\u{2022}\u{2022}\u{2022}567K")
    }

    // MARK: - Masking Format Verification

    func testExactlyFourDotsUsedForMasking() {
        let masked = NRICMasker.mask("S1234567A")
        let dotCount = masked.filter { $0 == "\u{2022}" }.count
        XCTAssertEqual(dotCount, 4, "Masked NRIC should contain exactly 4 bullet dots")
    }

    func testFourDotsForAllPrefixes() {
        let nrics = ["S1234567A", "T0123456Z", "F9876543B", "G1234567X", "M1234567K"]
        for nric in nrics {
            let masked = NRICMasker.mask(nric)
            let dotCount = masked.filter { $0 == "\u{2022}" }.count
            XCTAssertEqual(dotCount, 4, "Masked \(nric) should contain exactly 4 bullet dots, got \(dotCount)")
        }
    }

    func testMaskedOutputLength() {
        // Prefix (1) + 4 dots + last 4 chars = 9 characters total
        let masked = NRICMasker.mask("S1234567A")
        XCTAssertEqual(masked.count, 9)
    }

    func testMaskedOutputPreservesLastFourCharacters() {
        let masked = NRICMasker.mask("S1234567A")
        XCTAssertTrue(masked.hasSuffix("567A"))
    }

    func testMaskedOutputPreservesPrefix() {
        let masked = NRICMasker.mask("S1234567A")
        XCTAssertTrue(masked.hasPrefix("S"))
    }
}
