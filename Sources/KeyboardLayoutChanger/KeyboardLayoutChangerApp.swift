import SwiftUI

@main
struct KeyboardLayoutChangerApp: App {
    @StateObject private var controller = KeyboardLayoutController(
        loadMapping: { KeyMapping.load() },
        run: { try await ProcessRunner.run($0) },
        sleep: { try? await Task.sleep(for: $0) }
    )
    @StateObject private var launchAtLogin = LaunchAtLogin()

    var body: some Scene {
        MenuBarExtra {
            Button("Swap Command/Option Keys") {
                Task { await controller.apply() }
            }
            if let error = controller.lastError {
                Divider()
                Text("Last run failed: \(error)")
                Button("Copy Error") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error, forType: .string)
                }
            }
            Divider()
            Toggle("Launch at Login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.set($0) }
            ))
            if let error = launchAtLogin.lastError {
                Text("Launch at login: \(error)")
            }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: controller.status.symbolName)
        }
    }
}

extension ApplyStatus {
    var symbolName: String {
        switch self {
        case .idle: "keyboard"
        case .succeeded: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}
