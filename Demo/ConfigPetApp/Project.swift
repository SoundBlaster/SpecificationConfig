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
                .external(name: "SpecificationCore"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "ConfigPetApp",
            shared: true,
            buildAction: .buildAction(targets: ["ConfigPetApp"]),
            runAction: .runAction(executable: "ConfigPetApp")
        ),
    ]
)
