// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-interactive-cli",
    platforms: [
        .macOS(.v10_15)
    ],
    
    dependencies: [
        .package(url: "https://github.com/artman/Signals", from: "6.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.3")
    ],
    targets: [
        .executableTarget(
            name: "swift-interactive-cli",
            dependencies: [
                .product(name: "Signals", package: "Signals"),
                .product(name: "SQLite", package: "SQLite.swift")
            ])
    ]
    , swiftLanguageVersions: [.v5]
)
