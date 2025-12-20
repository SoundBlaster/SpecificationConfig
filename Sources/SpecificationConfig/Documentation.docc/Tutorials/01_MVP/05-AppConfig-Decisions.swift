import SpecificationConfig

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
