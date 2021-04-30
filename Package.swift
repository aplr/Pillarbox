// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Pillarbox",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "Pillarbox",
            targets: ["Pillarbox"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pinterest/PINCache.git",
            from: "3.0.3"
        ),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "0.0.2"
        )
    ],
    targets: [
        .target(
            name: "Pillarbox",
            dependencies: [
                .product(name: "PINCache", package: "PINCache"),
                .product(name: "DequeModule", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "PillarboxTests",
            dependencies: ["Pillarbox"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
