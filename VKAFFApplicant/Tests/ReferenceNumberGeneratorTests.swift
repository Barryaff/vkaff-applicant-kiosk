import XCTest
@testable import VKAFFApplicant

final class ReferenceNumberGeneratorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "lastReferenceDate")
        UserDefaults.standard.removeObject(forKey: "lastReferenceSequence")
    }

    func testReferenceFormat() {
        let ref = ReferenceNumberGenerator.generate()
        // Should match AFF-YYYYMMDD-XXXX
        let pattern = "^AFF-\\d{8}-\\d{4}$"
        XCTAssertNotNil(ref.range(of: pattern, options: .regularExpression))
    }

    func testSequentialGeneration() {
        let ref1 = ReferenceNumberGenerator.generate()
        let ref2 = ReferenceNumberGenerator.generate()

        // Extract sequence numbers
        let seq1 = ref1.suffix(4)
        let seq2 = ref2.suffix(4)

        XCTAssertEqual(seq1, "0001")
        XCTAssertEqual(seq2, "0002")
    }

    func testNewDayResetsSequence() {
        // Generate one today
        _ = ReferenceNumberGenerator.generate()

        // Simulate a new day by changing the stored date
        UserDefaults.standard.set("20200101", forKey: "lastReferenceDate")
        UserDefaults.standard.set(9999, forKey: "lastReferenceSequence")

        let ref = ReferenceNumberGenerator.generate()
        let seq = String(ref.suffix(4))

        // Should reset to 0001 since today's date differs from stored date
        XCTAssertEqual(seq, "0001")
    }
}
