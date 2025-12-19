import SpecificationConfig

decisionBindings: [
    AnyDecisionBinding(
        DecisionBinding(
            key: "pet.name",
            keyPath: \AppConfigDraft.petName,
            decisions: [sleepingNameDecision]
        )
    ),
],
