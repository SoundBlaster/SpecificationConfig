import SpecificationConfig

extension AppConfig {
    static let profile = SpecProfile<AppConfigDraft, AppConfig>(
        bindings: [],
        decisionBindings: [],
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
