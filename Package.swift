// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "Gate",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Gate",
            targets: ["Gate"]),
    ],
    targets: [
        .target(
            name: "Gate"),
        .testTarget(
            name: "GateTests",
            dependencies: ["Gate"]),
    ]
)
