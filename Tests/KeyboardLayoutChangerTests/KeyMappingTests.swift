import XCTest
@testable import KeyboardLayoutChanger

final class KeyMappingTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testUsesTheMappingFileWhenItExists() throws {
        let file = directory.appendingPathComponent("mapping.json")
        try #"{"UserKeyMapping":[{"custom":1}]}"#.write(to: file, atomically: true, encoding: .utf8)

        XCTAssertEqual(try KeyMapping.load(from: file), #"{"UserKeyMapping":[{"custom":1}]}"#)
    }

    func testFailsWhenTheMappingFileIsMissing() {
        let missing = directory.appendingPathComponent("missing.json")

        XCTAssertThrowsError(try KeyMapping.load(from: missing)) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "mapping file not found or unreadable: \(missing.path)"
            )
        }
    }
}