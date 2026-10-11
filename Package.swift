// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GameKey",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "GameKey",
            path: "Sources/GameKey"
        )
    ]
)
