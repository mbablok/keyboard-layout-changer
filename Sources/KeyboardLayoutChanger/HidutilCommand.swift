import Foundation

/// Which keyboard `hidutil` applies the mapping to. Change VendorID/ProductID
/// here to target a different keyboard (find them with `hidutil list`).
let keyboardMatchingJSON = #"{"VendorID":0x331a,"ProductID":0x5018}"#

/// The `hidutil property --matching … --set …` invocation for a key mapping.
struct HidutilCommand: Equatable, Sendable {
    let mappingJSON: String

    var executableURL: URL { URL(fileURLWithPath: "/usr/bin/hidutil") }

    var arguments: [String] {
        ["property", "--matching", keyboardMatchingJSON, "--set", mappingJSON]
    }
}
