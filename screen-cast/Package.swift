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
        .library(name: "GoogleCastClient", targets: ["GoogleCastClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.33.1"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.6.0")
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
