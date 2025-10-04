// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationTools",
    platforms: [
        .macOS(.v14)  // Minimum macOS version
    ],
    products: [
        .library(
            name: "FoundationTools",
            targets: ["FoundationTools"]
        ),
        .library(
            name: "FoundationTypes",
            targets: ["FoundationTypes"]
        ),
        .library(
            name: "FoundationCommon",
            targets: ["FoundationCommon"]
        ),
        .library(
            name: "FoundationUITools",
            targets: ["FoundationUITools"]
        ),
        .executable(
            name: "FoundationUIDemo",
            targets: ["FoundationUIDemo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/daikimat/depermaid.git", from: "1.1.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
        .package(url: "https://github.com/keyvariable/kvSIMD.swift.git", from: "1.1.0"),
        .package(url: "https://github.com/stackotter/swift-cross-ui", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "FoundationUIDemo",
            dependencies: [
                "FoundationUITools",
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "spm/Sources/FoundationUIDemo"
        ),
        .target(
            name: "FoundationTools",
            dependencies: [
                "FoundationCommon",
                "FoundationTypes",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OpenCombine", package: "OpenCombine")
            ],
            path: "spm/Sources/FoundationTools"
        ),
        .target(
            name: "FoundationCommon",
            path: "spm/Sources/FoundationCommon"
        ),
        .target(
            name: "FoundationTypes",
            dependencies: [
                .product(name: "kvSIMD", package: "kvSIMD.swift")
            ],
            path: "spm/Sources/FoundationTypes"
        ),
        .target(
            name: "FoundationUITools",
            dependencies: [
                "FoundationTypes",
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "spm/Sources/FoundationUITools"
        ),
        .testTarget(
            name: "FoundationToolsTests",
            dependencies: ["FoundationTools"],
            path: "spm/Tests/FoundationToolsTests"
        ),
        .testTarget(
            name: "FoundationCommonTests",
            dependencies: ["FoundationCommon"],
            path: "spm/Tests/FoundationCommonTests"
        ),
        .testTarget(
            name: "FoundationTypesTests",
            dependencies: ["FoundationTypes"],
            path: "spm/Tests/FoundationTypesTests"
        )
    ]
)
