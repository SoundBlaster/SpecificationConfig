import Configuration
import SpecificationConfig

let invalidValues: [AbsoluteConfigKey: ConfigValue] = [
    AbsoluteConfigKey(stringLiteral: "pet.name"):
        ConfigValue(stringLiteral: "    "), // empty name
]

let reader = ConfigReader.withEnvironmentOverrides(values: invalidValues)
let buildResult = ConfigPipeline.build(profile: AppConfig.profile, reader: reader)

if case let .failure(diagnostics, _) = buildResult {
    for diagnostic in diagnostics {
        print(diagnostic.message)
    }
}
