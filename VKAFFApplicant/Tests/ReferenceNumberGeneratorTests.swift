import XCTest
@testable import VKAFFApplicant

final class ReferenceNumberGeneratorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "lastReferenceDate")
        UserDefaults.standard.removeObject(forKey: "lastReferenceSequence")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "lastReferenceDate")
        UserDefaults.standard.removeObject(forKey: "lastReferenceSequence")
        super.tearDown()
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

    // MARK: - Regex Format Match

    func testFormatMatchesRegex() {
        let ref = ReferenceNumberGenerator.generate()
        let regex = try! NSRegularExpression(pattern: "^AFF-\\d{8}-\\d{4}$")
        let range = NSRange(ref.startIndex..., in: ref)
        let match = regex.firstMatch(in: ref, range: range)
        XCTAssertNotNil(match, "Reference '\(ref)' should match AFF-XXXXXXXX-XXXX format")
    }

    func testPrefixIsAFF() {
        let ref = ReferenceNumberGenerator.generate()
        XCTAssertTrue(ref.hasPrefix("AFF-"), "Reference should start with AFF-")
    }

    func testDatePartIsToday() {
        let ref = ReferenceNumberGenerator.generate()
        let components = ref.split(separator: "-")
        // AFF, YYYYMMDD, XXXX
        XCTAssertEqual(components.count, 3)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let todayStr = formatter.string(from: Date())

        XCTAssertEqual(String(components[1]), todayStr, "Date part should be today's date")
    }

    func testSequencePartIsFourDigits() {
        let ref = ReferenceNumberGenerator.generate()
        let seqPart = String(ref.suffix(4))
        XCTAssertNotNil(Int(seqPart), "Last 4 characters should be numeric")
        XCTAssertEqual(seqPart.count, 4, "Sequence should be exactly 4 digits")
    }

    // MARK: - Concurrent Generation (Thread Safety)

    func testConcurrentGenerationProducesUniqueSequences() {
        let iterations = 50
        let group = DispatchGroup()
        var references: [String] = []
        let lock = NSLock()

        for _ in 0..<iterations {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let ref = ReferenceNumberGenerator.generate()
                lock.lock()
                references.append(ref)
                lock.unlock()
                group.leave()
            }
        }

        let expectation = XCTestExpectation(description: "All concurrent generations complete")
        group.notify(queue: .main) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        // All references should be unique
        let uniqueRefs = Set(references)
        XCTAssertEqual(uniqueRefs.count, iterations,
                       "All \(iterations) concurrent reference numbers should be unique, got \(uniqueRefs.count)")
    }

    func testConcurrentGenerationAllMatchFormat() {
        let iterations = 20
        let group = DispatchGroup()
        var references: [String] = []
        let lock = NSLock()

        for _ in 0..<iterations {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let ref = ReferenceNumberGenerator.generate()
                lock.lock()
                references.append(ref)
                lock.unlock()
                group.leave()
            }
        }

        let expectation = XCTestExpectation(description: "All concurrent generations complete")
        group.notify(queue: .main) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        let pattern = "^AFF-\\d{8}-\\d{4}$"
        for ref in references {
            XCTAssertNotNil(ref.range(of: pattern, options: .regularExpression),
                           "Reference '\(ref)' should match expected format")
        }
    }

    // MARK: - Sequence Continuity

    func testMultipleSequentialGenerations() {
        for i in 1...10 {
            let ref = ReferenceNumberGenerator.generate()
            let seq = String(ref.suffix(4))
            XCTAssertEqual(seq, String(format: "%04d", i),
                           "Sequential generation \(i) should produce sequence \(String(format: "%04d", i))")
        }
    }
}
