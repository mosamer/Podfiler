// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Podfiler",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "podfiler", targets: ["Podfiler"]),
        .library(name: "PodfilerKit", targets: ["PodfilerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.3")),
        .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.1.10"),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "Podfiler",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "PodfilerKit",
                "Yams",
            ]
        ),
        .target(
            name: "PodfilerKit",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
        .testTarget(
            name: "PodfileKitTests",
            dependencies: [
                "PodfilerKit",
                "Nimble",
                "Quick",
            ]
        )
    ]
)
