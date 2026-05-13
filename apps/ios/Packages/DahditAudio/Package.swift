// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DahditAudio",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DahditAudio", targets: ["DahditAudio"])
    ],
    dependencies: [
        .package(path: "../DahditCore")
    ],
    targets: [
        .target(
            name: "DahditAudio",
            dependencies: ["DahditCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)

