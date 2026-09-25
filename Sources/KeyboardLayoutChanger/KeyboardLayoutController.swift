import Foundation

/// What the menu bar icon currently reports.
enum ApplyStatus: Equatable {
    case idle
    case succeeded
    case failed
}

struct CommandResult: Equatable {
    let exitCode: Int32
    let output: String
}

/// Applies the key mapping and briefly reports the outcome in the menu bar icon.
@MainActor
final class KeyboardLayoutController: ObservableObject {
    @Published private(set) var status: ApplyStatus = .idle
    /// Error text from the last failed run, kept until the next success.
    @Published private(set) var lastError: String?

    private let loadMapping: @MainActor () throws -> String
    private let run: @MainActor (HidutilCommand) async throws -> CommandResult
    private let sleep: @MainActor (Duration) async -> Void
    private let revertDelay: Duration
    /// Identifies the latest run, so an older run can neither report nor revert a newer result.
    private var runCount = 0

    init(
        loadMapping: @escaping @MainActor () throws -> String,
        run: @escaping @MainActor (HidutilCommand) async throws -> CommandResult,
        sleep: @escaping @MainActor (Duration) async -> Void,
        revertDelay: Duration = .seconds(2)
    ) {
        self.loadMapping = loadMapping
        self.run = run
        self.sleep = sleep
        self.revertDelay = revertDelay
    }

    func apply() async {
        runCount += 1
        let thisRun = runCount
        let failureText: String?
        do {
            failureText = await failure(of: HidutilCommand(mappingJSON: try loadMapping()))
        } catch {
            failureText = error.localizedDescription
        }
        guard thisRun == runCount else { return }
        if let failureText {
            lastError = failureText
            status = .failed
        } else {
            lastError = nil
            status = .succeeded
        }
        await sleep(revertDelay)
        if thisRun == runCount {
            status = .idle
        }
    }

    /// The error text for a failed run, or nil when hidutil succeeded.
    private func failure(of command: HidutilCommand) async -> String? {
        do {
            let result = try await run(command)
            let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            if result.exitCode == 0 {
                // hidutil prints the updated devices, and nothing (still exiting 0) when none matched.
                return output.isEmpty ? "Keyboard not found: no device matched \(keyboardMatchingJSON)" : nil
            }
            return output.isEmpty ? "hidutil exited with status \(result.exitCode)" : output
        } catch {
            return error.localizedDescription
        }
    }
}
