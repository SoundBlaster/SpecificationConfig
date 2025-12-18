// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ConfigPetApp",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "ConfigPetApp",
            targets: ["ConfigPetApp"]
        )
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "ConfigPetApp",
            dependencies: [
                .product(name: "SpecificationConfig", package: "SpecificationConfig")
            ],
            path: "ConfigPetApp"
        )
    ]
)
