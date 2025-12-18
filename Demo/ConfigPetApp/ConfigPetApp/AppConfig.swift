import Configuration
import Foundation
import SpecificationConfig
import SpecificationCore

struct AppConfigDraft {
    var petName: String?
    var isSleeping: Bool?
}

struct AppConfig {
    let petName: String
    let isSleeping: Bool

    private static let petNameFallbacks: [AnyDecisionSpec<AppConfigDraft, String>] = [
        AnyDecisionSpec(
            PredicateSpec<AppConfigDraft>(description: "Sleeping pet") { draft in
                draft.isSleeping == true
            }
            .returning("Sleepy")
        ),
    ]

    private static func resolvePetName(from draft: AppConfigDraft) -> String? {
        for decision in petNameFallbacks {
            if let name = decision.decide(draft) {
                return name
            }
        }
        return nil
    }

    static let profile = SpecProfile<AppConfigDraft, AppConfig>(
        bindings: [
            AnyBinding(
                Binding(
                    key: "pet.name",
                    keyPath: \AppConfigDraft.petName,
                    decoder: ConfigReader.string,
                    valueSpecs: [
                        AnySpecification { value in
                            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        },
                    ]
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
            let petName = draft.petName ?? resolvePetName(from: draft)
            guard let petName else {
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
