import Configuration
import Foundation
import SpecificationConfig
import SpecificationCore

/// Mutable draft used while bindings populate config values.
struct AppConfigDraft {
    var petName: String?
    var isSleeping: Bool?
}

/// Finalized configuration consumed by the demo UI.
struct AppConfig {
    let petName: String
    let isSleeping: Bool

    /// Spec profile defining bindings, validation, and finalization rules.
    static let profile = SpecProfile<AppConfigDraft, AppConfig>(
        bindings: [
            AnyBinding(
                Binding(
                    key: "pet.name",
                    keyPath: \AppConfigDraft.petName,
                    decoder: ConfigReader.string,
                    valueSpecs: [
                        SpecEntry(description: "Non-empty pet name") { value in
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
                    defaultValue: false,
                    contextualValueSpecs: [
                        ContextualSpecEntry(description: "Pets sleep at night") { context, isSleeping in
                            if context.flag(for: "nightTime") {
                                return isSleeping
                            }
                            return !isSleeping
                        },
                    ]
                )
            ),
        ],
        decisionBindings: [
            AnyDecisionBinding(
                DecisionBinding(
                    key: "pet.name",
                    keyPath: \AppConfigDraft.petName,
                    decisions: [
                        DecisionEntry(
                            description: "Sleeping pet",
                            predicate: { draft in draft.isSleeping == true },
                            result: "Sleepy"
                        ),
                    ]
                )
            ),
        ],
        contextProvider: AnyContextProvider(DemoContextProvider.shared),
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

/// Errors surfaced when required config values are missing.
enum AppConfigError: LocalizedError {
    case missingRequiredValue(key: String)

    var errorDescription: String? {
        switch self {
        case let .missingRequiredValue(key):
            "Missing required config value for key: \(key)"
        }
    }
}
