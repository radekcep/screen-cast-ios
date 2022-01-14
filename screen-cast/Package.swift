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
        .library(name: "GoogleCastClient", targets: ["GoogleCastClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.33.1")
    ],
    targets: [
        // MARK: - AppCore
        .target(
            name: "AppCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"]
        ),

        // MARK: - GoogleCastClient
        .target(
            name: "GoogleCastClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "GoogleCast")
            ]
        ),
        .binaryTarget(
            name: "GoogleCast",
            path: "Sources/GoogleCast/GoogleCast.xcframework"
        )
    ]
)
