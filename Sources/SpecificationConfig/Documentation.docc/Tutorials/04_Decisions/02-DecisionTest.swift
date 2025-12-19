import SpecificationConfig
import XCTest

struct AppConfigDraft {
    var petName: String?
    var isSleeping: Bool?
}

final class DecisionBindingTests: XCTestCase {
    func testDecisionReturnsSleepyWhenSleeping() {
        let binding = DecisionBinding(
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

        var draft = AppConfigDraft()
        draft.isSleeping = true

        let matched = binding.decisions.compactMap { $0.resolve(draft) }.first
        XCTAssertEqual(matched, "Sleepy")
    }
}
