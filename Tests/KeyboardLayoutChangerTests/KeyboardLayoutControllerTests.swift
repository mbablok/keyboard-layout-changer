import XCTest
@testable import KeyboardLayoutChanger

@MainActor
final class KeyboardLayoutControllerTests: XCTestCase {
    func testSuccessShowsCheckmarkThenRevertsAfterTwoSeconds() async {
        var ran: [HidutilCommand] = []
        var shownWhileWaiting: [ApplyStatus] = []
        var waited: [Duration] = []
        var controller: KeyboardLayoutController!
        controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { command in
                ran.append(command)
                return CommandResult(exitCode: 0, output: "RegistryID  Key  Value\n1007e8677  UserKeyMapping  (...)")
            },
            sleep: { duration in
                waited.append(duration)
                shownWhileWaiting.append(controller.status)
            }
        )

        await controller.apply()

        XCTAssertEqual(ran, [HidutilCommand(mappingJSON: "MAPPING")])
        XCTAssertEqual(shownWhileWaiting, [.succeeded])
        XCTAssertEqual(waited, [.seconds(2)])
        XCTAssertEqual(controller.status, .idle)
        XCTAssertNil(controller.lastError)
    }

    func testFailureShowsWarningAndKeepsTheErrorTextAfterReverting() async {
        var shownWhileWaiting: [ApplyStatus] = []
        var controller: KeyboardLayoutController!
        controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in CommandResult(exitCode: 1, output: "  no matching device\n") },
            sleep: { _ in shownWhileWaiting.append(controller.status) }
        )

        await controller.apply()

        XCTAssertEqual(shownWhileWaiting, [.failed])
        XCTAssertEqual(controller.status, .idle)
        XCTAssertEqual(controller.lastError, "no matching device")
    }

    func testFailureWithoutOutputReportsTheExitStatus() async {
        let controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in CommandResult(exitCode: 3, output: "") },
            sleep: { _ in }
        )

        await controller.apply()

        XCTAssertEqual(controller.lastError, "hidutil exited with status 3")
    }

    func testLaunchErrorIsReportedAsFailure() async {
        struct LaunchError: LocalizedError { var errorDescription: String? { "cannot launch" } }
        var shownWhileWaiting: [ApplyStatus] = []
        var controller: KeyboardLayoutController!
        controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in throw LaunchError() },
            sleep: { _ in shownWhileWaiting.append(controller.status) }
        )

        await controller.apply()

        XCTAssertEqual(shownWhileWaiting, [.failed])
        XCTAssertEqual(controller.lastError, "cannot launch")
    }

    func testSuccessClearsAnEarlierError() async {
        var exitCode: Int32 = 1
        let controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in CommandResult(exitCode: exitCode, output: "boom") },
            sleep: { _ in }
        )

        await controller.apply()
        exitCode = 0
        await controller.apply()

        XCTAssertNil(controller.lastError)
    }

    func testAnEarlierRunsTimerDoesNotRevertALaterRun() async {
        var exitCodes: [Int32] = [1, 0]
        var sleepers: [CheckedContinuation<Void, Never>] = []
        let controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in CommandResult(exitCode: exitCodes.removeFirst(), output: "matched") },
            sleep: { _ in await withCheckedContinuation { sleepers.append($0) } }
        )

        let first = Task { await controller.apply() }
        while sleepers.count < 1 { await Task.yield() }
        let second = Task { await controller.apply() }
        while sleepers.count < 2 { await Task.yield() }

        sleepers[0].resume()
        await first.value
        XCTAssertEqual(controller.status, .succeeded)

        sleepers[1].resume()
        await second.value
        XCTAssertEqual(controller.status, .idle)
    }

    func testARunThatFinishesLateLeavesANewerRunAlone() async {
        var pending: CheckedContinuation<CommandResult, Never>?
        var runs = 0
        let controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in
                runs += 1
                if runs == 1 {
                    return await withCheckedContinuation { pending = $0 }
                }
                return CommandResult(exitCode: 0, output: "matched")
            },
            sleep: { _ in }
        )

        let stale = Task { await controller.apply() }
        while pending == nil { await Task.yield() }
        await controller.apply()
        XCTAssertEqual(controller.status, .idle)

        pending?.resume(returning: CommandResult(exitCode: 0, output: ""))
        await stale.value

        XCTAssertEqual(runs, 2)
        XCTAssertEqual(controller.status, .idle)
        XCTAssertNil(controller.lastError)
    }

    func testAnUnreadableMappingFileFailsWithoutRunningHidutil() async {
        let mappingURL = URL(fileURLWithPath: "/tmp/absent-hidutil-mapping.json")
        var ran: [HidutilCommand] = []
        var shownWhileWaiting: [ApplyStatus] = []
        var controller: KeyboardLayoutController!
        controller = KeyboardLayoutController(
            loadMapping: { throw MappingFileError(url: mappingURL) },
            run: { command in
                ran.append(command)
                return CommandResult(exitCode: 0, output: "matched")
            },
            sleep: { _ in shownWhileWaiting.append(controller.status) }
        )

        await controller.apply()

        XCTAssertTrue(ran.isEmpty)
        XCTAssertEqual(shownWhileWaiting, [.failed])
        XCTAssertEqual(controller.lastError, "mapping file not found or unreadable: \(mappingURL.path)")
    }

    func testSilentSuccessMeansTheKeyboardWasNotFound() async {
        var shownWhileWaiting: [ApplyStatus] = []
        var controller: KeyboardLayoutController!
        controller = KeyboardLayoutController(
            loadMapping: { "MAPPING" },
            run: { _ in CommandResult(exitCode: 0, output: "\n") },
            sleep: { _ in shownWhileWaiting.append(controller.status) }
        )

        await controller.apply()

        XCTAssertEqual(shownWhileWaiting, [.failed])
        XCTAssertEqual(controller.lastError, "Keyboard not found: no device matched \(keyboardMatchingJSON)")
    }
}
