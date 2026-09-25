import Foundation

/// The `UserKeyMapping` JSON handed to `hidutil --set`.
enum KeyMapping {
    /// Same file the `swap-cmd-option-keys` fish function reads.
    static let defaultFileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".hidutil-swap-cmd-opt.json")

    /// Used when the mapping file is absent: swaps left Command/Option,
    /// maps right Control to right Option and the Application key to right Command.
    static let builtIn = """
        {
          "UserKeyMapping": [
            { "HIDKeyboardModifierMappingSrc": 0x7000000E3, "HIDKeyboardModifierMappingDst": 0x7000000E2 },
            { "HIDKeyboardModifierMappingSrc": 0x7000000E2, "HIDKeyboardModifierMappingDst": 0x7000000E3 },
            { "HIDKeyboardModifierMappingSrc": 0x7000000E4, "HIDKeyboardModifierMappingDst": 0x7000000E6 },
            { "HIDKeyboardModifierMappingSrc": 0x700000065, "HIDKeyboardModifierMappingDst": 0x7000000E7 }
          ]
        }
        """

    /// The mapping file's contents, or `builtIn` when it cannot be read.
    static func load(from url: URL = defaultFileURL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? builtIn
    }
}
