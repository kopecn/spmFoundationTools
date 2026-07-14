// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationTools",
    platforms: [
        .macOS(.v14),  // Minimum macOS version
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
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
            name: "FoundationInterfaces",
            targets: ["FoundationInterfaces"]
        ),
        .library(
            name: "FoundationTransactions",
            targets: ["FoundationTransactions"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/daikimat/depermaid.git", from: "1.1.0"),
        .package(url: "https://github.com/keyvariable/kvSIMD.swift.git", from: "1.1.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine", from: "0.14.0"),
    ],
    targets: [
        .target(
            name: "FoundationTools",
            dependencies: [
                "FoundationCommon",
                "FoundationTypes",
                "FoundationInterfaces",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "spm/Sources/FoundationTools"
        ),
        .target(
            name: "FoundationCommon",
            path: "spm/Sources/FoundationCommon"
        ),
        .target(
            name: "FoundationInterfaces",
            path: "spm/Sources/FoundationInterfaces"
        ),
        .target(
            name: "FoundationTypes",
            dependencies: [
                "FoundationInterfaces",
                .product(name: "kvSIMD", package: "kvSIMD.swift")
            ],
            path: "spm/Sources/FoundationTypes"
        ),
        .target(
            name: "FoundationTransactions",
            dependencies: [
                "FoundationInterfaces",
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineDispatch", package: "OpenCombine"),
            ],
            path: "spm/Sources/FoundationTransactions"
        ),
        .testTarget(
            name: "FoundationToolsTests",
            dependencies: [
                "FoundationTools",
                .product(name: "Logging", package: "swift-log"),
            ],
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
        ),
        .testTarget(
            name: "FoundationTransactionsTests",
            dependencies: ["FoundationTransactions"],
            path: "spm/Tests/FoundationTransactionsTests"
        )
    ]
)
