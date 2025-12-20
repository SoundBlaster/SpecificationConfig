import SpecificationConfig

let sleepingNameDecision = DecisionEntry(
    description: "Sleeping pet",
    predicate: { draft in draft.isSleeping == true },
    result: "Sleepy"
)
