// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: Array<SwiftSetting> = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
//    .enableExperimentalFeature("AccessLevelOnImport"),
//    .enableExperimentalFeature("VariadicGenerics"),
//    .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),
]

let package = Package(
    name: "GCDOperations",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "GCDCoreOperations",
            targets: ["GCDCoreOperations"]),
        .library(
            name: "GCDOperations",
            targets: ["GCDOperations"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GCDCoreOperations",
            swiftSettings: swiftSettings),
        .target(
            name: "GCDOperations",
            dependencies: ["GCDCoreOperations"],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "GCDCoreOperationsTests",
            dependencies: ["GCDCoreOperations"],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "GCDOperationsTests",
            dependencies: ["GCDOperations"],
            swiftSettings: swiftSettings),
    ]
)
