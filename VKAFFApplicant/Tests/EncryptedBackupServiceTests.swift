import XCTest
@testable import VKAFFApplicant

final class EncryptedBackupServiceTests: XCTestCase {

    private var service: EncryptedBackupService!
    private var testReference: String!

    override func setUp() {
        super.setUp()
        service = EncryptedBackupService()
        testReference = "TEST-\(UUID().uuidString.prefix(8))"
        // Clear any lingering test data in UserDefaults
        UserDefaults.standard.removeObject(forKey: "pendingUploadReferences")
    }

    override func tearDown() {
        // Clean up test files
        if let ref = testReference {
            service.removeBackup(for: ref)
        }
        // Clear pending references
        UserDefaults.standard.removeObject(forKey: "pendingUploadReferences")
        service = nil
        testReference = nil
        super.tearDown()
    }

    // MARK: - Save and Retrieve

    func testSaveAndRetrieveBackupData() {
        let pdfData = "Test PDF content".data(using: .utf8)!
        let jsonData = "{\"name\": \"test\"}".data(using: .utf8)!

        XCTAssertNoThrow(try service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference))

        let retrieved = service.getPendingData(for: testReference)
        XCTAssertNotNil(retrieved, "Should retrieve saved backup data")
        XCTAssertEqual(retrieved?.pdf, pdfData, "Retrieved PDF data should match saved data")
        XCTAssertEqual(retrieved?.json, jsonData, "Retrieved JSON data should match saved data")
    }

    func testSaveBackupCreatesFiles() {
        let pdfData = Data([0x25, 0x50, 0x44, 0x46])  // %PDF header bytes
        let jsonData = "{}".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)

        let result = service.getPendingData(for: testReference)
        XCTAssertNotNil(result, "Backup files should exist after save")
    }

    func testRetrieveNonExistentBackupReturnsNil() {
        let result = service.getPendingData(for: "NONEXISTENT-REF-12345678")
        XCTAssertNil(result, "Should return nil for non-existent reference")
    }

    // MARK: - getPendingReferences

    func testGetPendingReferencesReturnsSavedReferences() {
        let pdfData = "pdf".data(using: .utf8)!
        let jsonData = "json".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)

        let pending = service.getPendingReferences()
        XCTAssertTrue(pending.contains(testReference),
                      "Pending references should contain the saved reference")
    }

    func testGetPendingReferencesEmptyByDefault() {
        let pending = service.getPendingReferences()
        XCTAssertTrue(pending.isEmpty, "Pending references should be empty by default")
    }

    func testSaveDuplicateReferenceDoesNotDuplicate() {
        let pdfData = "pdf".data(using: .utf8)!
        let jsonData = "json".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)
        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)

        let pending = service.getPendingReferences()
        let count = pending.filter { $0 == testReference }.count
        XCTAssertEqual(count, 1, "Saving the same reference twice should not create duplicates in pending list")
    }

    func testMultipleSavesTrackAllReferences() {
        let pdfData = "pdf".data(using: .utf8)!
        let jsonData = "json".data(using: .utf8)!

        let ref1 = testReference!
        let ref2 = "TEST-\(UUID().uuidString.prefix(8))"

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: ref1)
        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: ref2)

        let pending = service.getPendingReferences()
        XCTAssertTrue(pending.contains(ref1))
        XCTAssertTrue(pending.contains(ref2))

        // Clean up the second reference
        service.removeBackup(for: ref2)
    }

    // MARK: - Remove Backup

    func testRemoveBackupRemovesData() {
        let pdfData = "pdf".data(using: .utf8)!
        let jsonData = "json".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)

        // Verify it exists first
        XCTAssertNotNil(service.getPendingData(for: testReference))

        service.removeBackup(for: testReference)

        // Verify files are removed
        let result = service.getPendingData(for: testReference)
        XCTAssertNil(result, "Backup data should be nil after removal")
    }

    func testRemoveBackupRemovesFromPendingList() {
        let pdfData = "pdf".data(using: .utf8)!
        let jsonData = "json".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)
        service.removeBackup(for: testReference)

        let pending = service.getPendingReferences()
        XCTAssertFalse(pending.contains(testReference),
                       "Reference should be removed from pending list after removeBackup")
    }

    func testRemoveNonExistentBackupDoesNotCrash() {
        // Should not throw or crash when removing a non-existent reference
        service.removeBackup(for: "NONEXISTENT-REF-99999999")
    }

    // MARK: - Export All

    func testExportAllReturnsNilWhenEmpty() {
        let exportURL = service.exportAll()
        XCTAssertNil(exportURL, "exportAll should return nil when no pending uploads exist")
    }

    func testExportAllReturnsDirectoryWithContent() {
        let pdfData = "export-pdf".data(using: .utf8)!
        let jsonData = "export-json".data(using: .utf8)!

        try? service.saveBackup(pdfData: pdfData, jsonData: jsonData, referenceNumber: testReference)

        guard let exportURL = service.exportAll() else {
            XCTFail("exportAll should return a URL when pending uploads exist")
            return
        }

        // Verify exported files exist
        let pdfURL = exportURL.appendingPathComponent("\(testReference!).pdf")
        let jsonURL = exportURL.appendingPathComponent("\(testReference!).json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path),
                      "Exported PDF file should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path),
                      "Exported JSON file should exist")

        // Clean up export directory
        try? FileManager.default.removeItem(at: exportURL)
    }
}
