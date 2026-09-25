import Foundation
import ServiceManagement

/// The `SMAppService` calls and the persisted user choice behind the Launch at Login item.
struct LoginItemControls {
    var status: @MainActor () -> SMAppService.Status
    var register: @MainActor () throws -> Void
    var unregister: @MainActor () throws -> Void
    /// Set when the user turns the item off, so later launches leave it off.
    var isDisabledByUser: @MainActor () -> Bool
    var setDisabledByUser: @MainActor (Bool) -> Void

    static func live(defaults: UserDefaults = .standard) -> LoginItemControls {
        let key = "LaunchAtLoginDisabledByUser"
        return LoginItemControls(
            status: { SMAppService.mainApp.status },
            register: { try SMAppService.mainApp.register() },
            unregister: { try SMAppService.mainApp.unregister() },
            isDisabledByUser: { defaults.bool(forKey: key) },
            setDisabledByUser: { defaults.set($0, forKey: key) }
        )
    }
}

/// Registers the app as a login item and reports the state macOS actually adopted.
@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled: Bool
    /// Why the login item is not active although it should be, or why the last change failed.
    @Published private(set) var lastError: String?

    private let controls: LoginItemControls

    init(controls: LoginItemControls = .live()) {
        self.controls = controls
        isEnabled = controls.status() == .enabled
        lastError = Self.notice(for: controls.status())
        if controls.status() == .notRegistered, !controls.isDisabledByUser() {
            set(true)
        }
    }

    /// Re-reads what macOS adopted, e.g. after approval was granted in System Settings.
    func refresh() {
        sync(after: nil)
    }

    func set(_ enabled: Bool) {
        do {
            if enabled {
                try controls.register()
            } else {
                try controls.unregister()
            }
            controls.setDisabledByUser(!enabled)
            sync(after: nil)
        } catch {
            sync(after: error)
        }
    }

    private func sync(after thrown: Error?) {
        isEnabled = controls.status() == .enabled
        lastError = thrown?.localizedDescription ?? Self.notice(for: controls.status())
    }

    private static func notice(for status: SMAppService.Status) -> String? {
        switch status {
        case .enabled, .notRegistered: nil
        case .requiresApproval:
            "Approval required: allow this app in System Settings → General → Login Items"
        case .notFound:
            "macOS does not recognize this build as a login item: turn Launch at Login on again"
        @unknown default:
            nil
        }
    }
}