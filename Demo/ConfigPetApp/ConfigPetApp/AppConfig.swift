import Configuration
import SpecificationConfig

struct AppConfigDraft {
    var petName: String?
    var isSleeping: Bool?
}

struct AppConfig {
    let petName: String
    let isSleeping: Bool

    static let profile = SpecProfile<AppConfigDraft, AppConfig>(
        bindings: [
            AnyBinding(
                Binding(
                    key: "pet.name",
                    keyPath: \AppConfigDraft.petName,
                    decoder: ConfigReader.string
                )
            ),
            AnyBinding(
                Binding(
                    key: "pet.isSleeping",
                    keyPath: \AppConfigDraft.isSleeping,
                    decoder: ConfigReader.bool,
                    defaultValue: false
                )
            ),
        ],
        finalize: { draft in
            guard let petName = draft.petName else {
                throw AppConfigError.missingRequiredValue(key: "pet.name")
            }
            guard let isSleeping = draft.isSleeping else {
                throw AppConfigError.missingRequiredValue(key: "pet.isSleeping")
            }
            return AppConfig(petName: petName, isSleeping: isSleeping)
        },
        makeDraft: AppConfigDraft.init
    )
}

enum AppConfigError: LocalizedError {
    case missingRequiredValue(key: String)

    var errorDescription: String? {
        switch self {
        case let .missingRequiredValue(key):
            "Missing required config value for key: \(key)"
        }
    }
}
