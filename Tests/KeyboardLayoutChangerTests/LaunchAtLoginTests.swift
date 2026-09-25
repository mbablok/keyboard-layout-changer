import XCTest
import ServiceManagement
@testable import KeyboardLayoutChanger

@MainActor
final class LaunchAtLoginTests: XCTestCase {
    @MainActor
    private final class Fake {
        var status: SMAppService.Status = .notRegistered
        var registrations = 0
        var unregistrations = 0
        var disabledByUser = false
        var registerError: Error?
        /// When false, `register()` returns without macOS adopting the login item.
        var adoptsOnRegister = true

        var controls: LoginItemControls {
            LoginItemControls(
                status: { self.status },
                register: {
                    if let error = self.registerError { throw error }
                    self.registrations += 1
                    self.status = self.adoptsOnRegister ? .enabled : .requiresApproval
                },
                unregister: {
                    self.unregistrations += 1
                    self.status = .notRegistered
                },
                isDisabledByUser: { self.disabledByUser },
                setDisabledByUser: { self.disabledByUser = $0 }
            )
        }
    }

    private struct Failure: LocalizedError {
        var errorDescription: String? { "register refused" }
    }

    func testLaunchRegistersTheAppSoItStartsAtLogin() {
        let fake = Fake()

        let item = LaunchAtLogin(controls: fake.controls)

        XCTAssertEqual(fake.registrations, 1)
        XCTAssertTrue(item.isEnabled)
        XCTAssertNil(item.lastError)
    }

    func testLaunchLeavesTheLoginItemAloneAfterTheUserTurnedItOff() {
        let fake = Fake()
        fake.disabledByUser = true

        let item = LaunchAtLogin(controls: fake.controls)

        XCTAssertEqual(fake.registrations, 0)
        XCTAssertFalse(item.isEnabled)
        XCTAssertNil(item.lastError)
    }

    func testTurningTheLoginItemOffIsRememberedAcrossLaunches() {
        let fake = Fake()
        let item = LaunchAtLogin(controls: fake.controls)

        item.set(false)

        XCTAssertEqual(fake.unregistrations, 1)
        XCTAssertTrue(fake.disabledByUser)
        XCTAssertFalse(item.isEnabled)

        let relaunched = LaunchAtLogin(controls: fake.controls)

        XCTAssertEqual(fake.registrations, 1)
        XCTAssertFalse(relaunched.isEnabled)
    }

    func testTurningTheLoginItemOnAfterTheUserTurnedItOffRegistersAgain() {
        let fake = Fake()
        fake.disabledByUser = true
        let item = LaunchAtLogin(controls: fake.controls)

        item.set(true)

        XCTAssertEqual(fake.registrations, 1)
        XCTAssertFalse(fake.disabledByUser)
        XCTAssertTrue(item.isEnabled)
    }

    func testAToggleThatMacOSDoesNotAdoptReportsApprovalInsteadOfSilentlyReverting() {
        let fake = Fake()
        fake.disabledByUser = true
        fake.adoptsOnRegister = false
        let item = LaunchAtLogin(controls: fake.controls)

        item.set(true)

        XCTAssertFalse(item.isEnabled)
        XCTAssertNotNil(item.lastError)
        XCTAssertTrue(item.lastError?.contains("System Settings") ?? false)
    }

    func testARejectedRegistrationReportsTheSystemError() {
        let fake = Fake()
        fake.disabledByUser = true
        fake.registerError = Failure()
        let item = LaunchAtLogin(controls: fake.controls)

        item.set(true)

        XCTAssertFalse(item.isEnabled)
        XCTAssertEqual(item.lastError, "register refused")
    }

    func testRefreshPicksUpApprovalGrantedInSystemSettings() {
        let fake = Fake()
        fake.disabledByUser = true
        fake.status = .requiresApproval
        let item = LaunchAtLogin(controls: fake.controls)

        XCTAssertFalse(item.isEnabled)
        XCTAssertTrue(item.lastError?.contains("Approval required") ?? false)

        fake.status = .enabled
        item.refresh()

        XCTAssertTrue(item.isEnabled)
        XCTAssertNil(item.lastError)
    }
}