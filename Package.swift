// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "qopen",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "qopen")
    ]
)
