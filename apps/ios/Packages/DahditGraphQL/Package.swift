// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DahditGraphQL",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DahditGraphQL", targets: ["DahditGraphQL"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.1.1"),
        .package(path: "../DahditCore")
    ],
    targets: [
        .target(
            name: "DahditGraphQL",
            dependencies: [
                "DahditCore",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "DahditGraphQLTests",
            dependencies: [
                "DahditGraphQL",
                "DahditCore"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)
