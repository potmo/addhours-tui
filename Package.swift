// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-interactive-cli",
    platforms: [
        .macOS(.v10_15)
    ],
    
    dependencies: [
        //.package(url: "https://github.com/Kitura/BlueSignals.git", exact: Version(2, 0, 1))
        .package(url: "https://github.com/artman/Signals", from: "6.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift-interactive-cli",
            dependencies: [
                .product(name: "Signals", package: "Signals")
            ])
    ]
    , swiftLanguageVersions: [.v5]
)
