// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FPSCounter",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "FPSCounter", targets: ["FPSCounter"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "FPSCounter", path: "Sources"),
    ]
)
