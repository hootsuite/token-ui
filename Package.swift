// swift-tools-version:4.2

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
        .testTarget(name: "TokenUITests", dependencies: ["TokenUI"], path: "Tests")
    ]
)
