import Foundation

/// Runs a hidutil command off the main thread, capturing stdout and stderr together.
enum ProcessRunner {
    static func run(_ command: HidutilCommand) async throws -> CommandResult {
        try await Task.detached {
            let process = Process()
            process.executableURL = command.executableURL
            process.arguments = command.arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            let output = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return CommandResult(
                exitCode: process.terminationStatus,
                output: String(decoding: output, as: UTF8.self)
            )
        }.value
    }
}
