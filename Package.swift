// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WinKeys",
    platforms: [.macOS(.v10_13)],
    targets: [
        .executableTarget(name: "WinKeys", path: "Sources/WinKeys")
    ]
)
