// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DahditCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DahditCore", targets: ["DahditCore"])
    ],
    targets: [
        .target(
            name: "DahditCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "DahditCoreTests",
            dependencies: ["DahditCore"],
            resources: [.process("Resources")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)

