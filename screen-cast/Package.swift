// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "screen-cast",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "AppView", targets: ["AppView"]),
        .library(name: "ExtensionCore", targets: ["ExtensionCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.33.1"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.1.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        // MARK: - AppCore
        .target(
            name: "AppCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "GoogleCastClient"),
                .target(name: "SettingsClient"),
                .target(name: "TCAHelpers")
            ]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"]
        ),

        // MARK: - AppView
        .target(
            name: "AppView",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "AppCore")
            ]
        ),

        // MARK: - ExtensionCore
        .target(
            name: "ExtensionCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "GoogleCastClient"),
                .target(name: "SettingsClient"),
                .target(name: "HLSClient")
            ]
        ),

        // MARK: - GoogleCastClient
        .target(
            name: "GoogleCastClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "GoogleCast")
            ]
        ),
        .binaryTarget(
            name: "GoogleCast",
            path: "Sources/GoogleCast/GoogleCast.xcframework"
        ),

        // MARK: - HLSClient
        .target(
            name: "HLSClient",
            dependencies: [
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            resources: [
                .copy("Resources")
            ]
        ),

        // MARK: - SettingsClient
        .target(
            name: "SettingsClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "GoogleCastClient")
            ]
        ),

        // MARK: - TCAHelpers
        .target(
            name: "TCAHelpers",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
