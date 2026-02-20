// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Pulse",
            path: "Sources/Pulse"
        ),
        .executableTarget(
            name: "PulseTests",
            path: "Tests/PulseTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
