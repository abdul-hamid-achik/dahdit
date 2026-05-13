// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DahditUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DahditUI", targets: ["DahditUI"])
    ],
    dependencies: [
        .package(path: "../DahditCore")
    ],
    targets: [
        .target(
            name: "DahditUI",
            dependencies: ["DahditCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)

