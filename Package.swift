// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QuickMinimalNotetaker",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "QuickMinimalNotetaker",
            path: "Sources/QuickMinimalNotetaker",
            resources: [.copy("Resources/background.jpg")]
        )
    ]
)
