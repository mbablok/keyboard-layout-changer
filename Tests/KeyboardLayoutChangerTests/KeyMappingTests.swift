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

        XCTAssertEqual(KeyMapping.load(from: file), #"{"UserKeyMapping":[{"custom":1}]}"#)
    }

    func testFallsBackToTheBuiltInMappingWhenTheFileIsMissing() {
        let missing = directory.appendingPathComponent("missing.json")

        XCTAssertEqual(KeyMapping.load(from: missing), KeyMapping.builtIn)
    }

    func testBuiltInMappingSwapsCommandAndOptionLikeTheFishFunction() {
        for pair in [
            "0x7000000E3", "0x7000000E2", "0x7000000E4", "0x7000000E6", "0x700000065", "0x7000000E7",
        ] {
            XCTAssertTrue(KeyMapping.builtIn.contains(pair), "missing \(pair)")
        }
        XCTAssertTrue(KeyMapping.builtIn.contains("UserKeyMapping"))
    }
}
