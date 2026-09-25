// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyboardLayoutChanger",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "KeyboardLayoutChanger",
            path: "Sources/KeyboardLayoutChanger"
        ),
        .testTarget(
            name: "KeyboardLayoutChangerTests",
            dependencies: ["KeyboardLayoutChanger"],
            path: "Tests/KeyboardLayoutChangerTests"
        ),
    ]
)
