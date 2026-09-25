import XCTest
@testable import KeyboardLayoutChanger

final class HidutilCommandTests: XCTestCase {
    func testRunsHidutilPropertyMatchingTheKeyboardAndSettingTheMapping() {
        let command = HidutilCommand(mappingJSON: #"{"UserKeyMapping":[]}"#)

        XCTAssertEqual(command.executableURL.path, "/usr/bin/hidutil")
        XCTAssertEqual(command.arguments, [
            "property",
            "--matching", #"{"VendorID":0x331a,"ProductID":0x5018}"#,
            "--set", #"{"UserKeyMapping":[]}"#,
        ])
    }
}
