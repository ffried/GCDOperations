// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GCDCoreOperations",
            dependencies: []),
        .target(
            name: "GCDOperations",
            dependencies: ["GCDCoreOperations"]),
        .testTarget(
            name: "GCDCoreOperationsTests",
            dependencies: ["GCDCoreOperations"]),
        .testTarget(
            name: "GCDOperationsTests",
            dependencies: ["GCDOperations"]),
    ]
)
