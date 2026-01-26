import Configuration
import SpecificationConfig

struct AppDraft {
    var petName: String?
}

struct AppConfig {
    let petName: String
}

enum AppConfigError: Error {
    case missingName
}

let profile = SpecProfile<AppDraft, AppConfig>(
    bindings: [
        AnyBinding(
            Binding(
                key: "pet.name",
                keyPath: \AppDraft.petName,
                decoder: ConfigReader.string
            )
        ),
    ],
    finalize: { draft in
        guard let petName = draft.petName else {
            throw AppConfigError.missingName
        }
        return AppConfig(petName: petName)
    },
    makeDraft: AppDraft.init
)

let reader = ConfigReader(
    provider: InMemoryProvider(values: [
        AbsoluteConfigKey(stringLiteral: "pet.name"): ConfigValue(stringLiteral: "Clover"),
    ])
)

let result = ConfigPipeline.build(profile: profile, reader: reader)
_ = result
