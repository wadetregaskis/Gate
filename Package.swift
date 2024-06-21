// swift-tools-version: 5.9
// 5.9 required for `enableExperimentalFeature`. 😕

import PackageDescription

let enables = ["AccessLevelOnImport",
               "BareSlashRegexLiterals",
               "ConciseMagicFile",
               "DeprecateApplicationMain",
               "DisableOutwardActorInference",
               "DynamicActorIsolation",
               "ExistentialAny",
               "ForwardTrailingClosures",
               //"FullTypedThrows", // Not ready yet, in Swift 6.  https://forums.swift.org/t/where-is-fulltypedthrows/72346/15
               "GlobalConcurrency",
               "ImplicitOpenExistentials",
               "ImportObjcForwardDeclarations",
               "InferSendableFromCaptures",
               "InternalImportsByDefault",
               "IsolatedDefaultValues",
               "StrictConcurrency"]

let settings: [SwiftSetting] = enables.flatMap {
    [.enableUpcomingFeature($0), .enableExperimentalFeature($0)]
}

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
            name: "Gate",
            swiftSettings: settings),
        .testTarget(
            name: "GateTests",
            dependencies: ["Gate"],
            swiftSettings: settings),
    ]
)
