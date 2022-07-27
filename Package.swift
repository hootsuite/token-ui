// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TokenUI",
    products: [
        .library(name: "TokenUI", targets: ["TokenUI"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "TokenUI", path: "Sources"),
        .testTarget(name: "TokenTests", dependencies: ["TokenUI"], path: "Tests")
    ]
)
