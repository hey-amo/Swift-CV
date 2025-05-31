// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "SwiftDataDemo",
    platforms: [
        .macOS(.v14),     // macOS 14.0 - minimum for SwiftData
        .iOS(.v17),       // iOS 17 - minimum for SwiftData
        .tvOS(.v17),      // tvOS 17 - minimum for SwiftData
        .watchOS(.v10),   // watchOS 10 - minimum for SwiftData
        .visionOS(.v1)    // visionOS 1.0 - minimum for SwiftData
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftDataDemo",
            targets: ["SwiftDataDemo"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftDataDemo"),
        .testTarget(
            name: "SwiftDataDemoTests",
            dependencies: ["SwiftDataDemo"]
        ),
    ]
)

