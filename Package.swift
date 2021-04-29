// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Pillarbox",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10),
        .macOS(.v10_12)
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
    ],
    targets: [
        .target(
            name: "Pillarbox",
            dependencies: ["PINCache"]
        ),
        .testTarget(
            name: "PillarboxTests",
            dependencies: ["Pillarbox"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
