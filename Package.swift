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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/daikimat/depermaid.git", from: "1.1.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
    ],
    targets: [
        .executableTarget(
            name: "FoundationUIDemo", 
            dependencies: [
                "FoundationTools",
                .product(name: "OpenCombine", package: "OpenCombine"),
            ], 
            path: "spm/Sources/FoundationUIDemo"
        ),
        .target(
            name: "FoundationTools",
            dependencies: [
                "FoundationCommon",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OpenCombine", package: "OpenCombine"),
            ],
            path: "spm/Sources/FoundationTools",
        ),
        .target(
            name: "FoundationCommon",
            path: "spm/Sources/FoundationCommon"
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
    ]
)
