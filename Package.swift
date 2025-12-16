// swift-tools-version: 6.0
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
            targets: ["SpecificationConfig"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0"),
        .package(url: "https://github.com/SoundBlaster/SpecificationCore", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SpecificationConfig",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "SpecificationCore", package: "SpecificationCore"),
            ]
        ),
        .testTarget(
            name: "SpecificationConfigTests",
            dependencies: ["SpecificationConfig"]
        ),
    ]
)
