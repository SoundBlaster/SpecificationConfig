// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpecificationConfig",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "SpecificationConfig",
            targets: ["SpecificationConfig"],
        ),
    ],
    targets: [
        .target(
            name: "SpecificationConfig",
        ),
        .testTarget(
            name: "SpecificationConfigTests",
            dependencies: ["SpecificationConfig"],
        ),
    ]
)
