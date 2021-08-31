// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Podfiler",
    products: [
        .executable(name: "podfiler", targets: ["Podfiler"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "0.3.0")),
        .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.1.10"),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "4.0.6")),
    ],
    targets: [
        .executableTarget(
            name: "Podfiler",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "Yams",
            ]
        ),
    ]
)
