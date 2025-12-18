// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "SpecificationConfig": .framework,
            "SpecificationCore": .framework,
        ]
    )
#endif

let package = Package(
    name: "ConfigPetAppDependencies",
    dependencies: [
        .package(path: "../../.."),
    ]
)
