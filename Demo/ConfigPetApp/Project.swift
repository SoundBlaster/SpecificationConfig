import ProjectDescription

let project = Project(
    name: "ConfigPetApp",
    targets: [
        .target(
            name: "ConfigPetApp",
            destinations: .macOS,
            product: .app,
            bundleId: "com.example.ConfigPetApp",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["ConfigPetApp/**"],
            resources: ["config.json"],
            dependencies: [
                .external(name: "SpecificationConfig"),
            ]
        ),
        .target(
            name: "ConfigPetAppTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.example.ConfigPetAppTests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["ConfigPetAppTests/**"],
            dependencies: [
                .target(name: "ConfigPetApp"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "ConfigPetApp",
            shared: true,
            buildAction: .buildAction(targets: ["ConfigPetApp"]),
            testAction: .targets(["ConfigPetAppTests"]),
            runAction: .runAction(executable: "ConfigPetApp")
        ),
    ]
)
