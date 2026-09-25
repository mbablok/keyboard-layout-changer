import Foundation

/// The `UserKeyMapping` JSON handed to `hidutil --set`.
enum KeyMapping {
    /// Same file the `swap-cmd-option-keys` fish function reads; the only source of the mapping.
    static let defaultFileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".hidutil-swap-cmd-opt.json")

    /// The mapping file's contents, exactly as the fish function's `cat` hands them to hidutil.
    static func load(from url: URL = defaultFileURL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw MappingFileError(url: url)
        }
    }
}

/// The mapping file could not be read, so there is no mapping to apply.
struct MappingFileError: LocalizedError {
    let url: URL

    var errorDescription: String? { "mapping file not found or unreadable: \(url.path)" }
}