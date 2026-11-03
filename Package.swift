// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PoxiOFFX",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PoxiOFFXCore"),
        .executableTarget(name: "PoxiOFFX", dependencies: ["PoxiOFFXCore"]),
        .testTarget(name: "PoxiOFFXCoreTests", dependencies: ["PoxiOFFXCore"]),
    ]
)
