import Configuration
@testable import SpecificationConfig
import XCTest

final class AsyncDecisionBindingTests: XCTestCase {
    // MARK: - Test Types

    struct Draft {
        var petName: String?
        var isSleeping: Bool?
    }

    struct Config: Equatable {
        let petName: String
        let isSleeping: Bool
    }

    enum TestError: Error {
        case missingName
        case missingSleepFlag
    }

    // MARK: - S7: AsyncDecisionEntry resolves value

    func testAsyncDecisionEntryMatchesAndResolvesValue() async {
        let entry = AsyncDecisionEntry<Draft, String>(
            description: "Sleeping pet",
            predicate: { (draft: Draft) async in draft.isSleeping == true },
            result: "Sleepy"
        )

        var draft = Draft()
        draft.isSleeping = true

        let result = await entry.resolve(draft)
        XCTAssertEqual(result, "Sleepy")
    }

    func testAsyncDecisionEntryNoMatch() async {
        let entry = AsyncDecisionEntry<Draft, String>(
            description: "Sleeping pet",
            predicate: { (draft: Draft) async in draft.isSleeping == true },
            result: "Sleepy"
        )

        var draft = Draft()
        draft.isSleeping = false

        let result = await entry.resolve(draft)
        XCTAssertNil(result)
    }

    func testAsyncDecisionEntryWithDecideClosure() async {
        let entry = AsyncDecisionEntry<Draft, String>(
            description: "Custom decision"
        ) { (draft: Draft) async in
            draft.isSleeping == true ? "ZZZ" : nil
        }

        var draft = Draft()
        draft.isSleeping = true

        let result = await entry.resolve(draft)
        XCTAssertEqual(result, "ZZZ")
    }

    // MARK: - S8: AsyncDecisionBinding applies first match and records trace

    func testAsyncDecisionBindingAppliesFirstMatchAndRecordsTrace() async {
        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \Draft.isSleeping,
            decoder: ConfigReader.bool
        )

        let asyncDecision = AsyncDecisionEntry<Draft, String>(
            description: "Async sleeping pet",
            predicate: { (draft: Draft) async in draft.isSleeping == true },
            result: "Sleepy"
        )

        let asyncDecisionBinding = AsyncDecisionBinding(
            key: "pet.name",
            keyPath: \Draft.petName,
            decisions: [asyncDecision]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(sleepingBinding)],
            asyncDecisionBindings: [AnyAsyncDecisionBinding(asyncDecisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw TestError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw TestError.missingSleepFlag
                }
                return Config(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { Draft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.isSleeping": true,
        ])
        let reader = ConfigReader(provider: provider)

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config, Config(petName: "Sleepy", isSleeping: true))
            XCTAssertEqual(snapshot.decisionTraces.count, 1)
            let trace = snapshot.decisionTrace(forKey: "pet.name")
            XCTAssertEqual(trace?.decisionName, "Async sleeping pet")
            XCTAssertEqual(trace?.matchedIndex, 0)
            let resolved = snapshot.value(forKey: "pet.name")
            XCTAssertEqual(resolved?.stringifiedValue, "Sleepy")
            XCTAssertEqual(resolved?.provenance, .decisionFallback)
        case .failure:
            XCTFail("Expected async decision fallback to succeed")
        }
    }

    // MARK: - S9: AsyncDecisionBinding no-match produces diagnostic

    func testAsyncDecisionBindingNoMatchAddsDiagnostic() async {
        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \Draft.isSleeping,
            decoder: ConfigReader.bool
        )

        let asyncDecision = AsyncDecisionEntry<Draft, String>(
            description: "Async sleeping pet",
            predicate: { (draft: Draft) async in draft.isSleeping == true },
            result: "Sleepy"
        )

        let asyncDecisionBinding = AsyncDecisionBinding(
            key: "pet.name",
            keyPath: \Draft.petName,
            decisions: [asyncDecision]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(sleepingBinding)],
            asyncDecisionBindings: [AnyAsyncDecisionBinding(asyncDecisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw TestError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw TestError.missingSleepFlag
                }
                return Config(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { Draft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.isSleeping": false,
        ])
        let reader = ConfigReader(provider: provider)

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)

        switch result {
        case .success:
            XCTFail("Expected async decision fallback failure")
        case let .failure(diagnostics, snapshot):
            XCTAssertTrue(diagnostics.hasErrors)
            XCTAssertEqual(snapshot.decisionTraces.count, 0)
            let error = diagnostics.diagnostics.first { $0.key == "pet.name" }
            XCTAssertTrue(error?.message.contains("Async decision fallback") ?? false)
        }
    }

    // MARK: - S10: AsyncDecisionBinding skips when draft field already set

    func testAsyncDecisionBindingSkipsWhenFieldAlreadySet() async {
        let nameBinding = Binding(
            key: "pet.name",
            keyPath: \Draft.petName,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \Draft.isSleeping,
            decoder: ConfigReader.bool
        )

        let asyncDecision = AsyncDecisionEntry<Draft, String>(
            description: "Should be skipped",
            predicate: { (_: Draft) async in true },
            result: "OverriddenName"
        )

        let asyncDecisionBinding = AsyncDecisionBinding(
            key: "pet.name",
            keyPath: \Draft.petName,
            decisions: [asyncDecision]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(nameBinding), AnyBinding(sleepingBinding)],
            asyncDecisionBindings: [AnyAsyncDecisionBinding(asyncDecisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw TestError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw TestError.missingSleepFlag
                }
                return Config(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { Draft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.name": "Buddy",
            "pet.isSleeping": false,
        ])
        let reader = ConfigReader(provider: provider)

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)

        switch result {
        case let .success(config, _):
            // Name should be "Buddy" from the regular binding, not "OverriddenName"
            XCTAssertEqual(config.petName, "Buddy")
            XCTAssertFalse(config.isSleeping)
        case .failure:
            XCTFail("Expected success when field already set")
        }
    }

    // MARK: - S11: Full pipeline buildAsync with async decisions

    func testAsyncDecisionBindingMultipleDecisionsPicksFirst() async {
        let sleepingBinding = Binding(
            key: "pet.isSleeping",
            keyPath: \Draft.isSleeping,
            decoder: ConfigReader.bool
        )

        let firstDecision = AsyncDecisionEntry<Draft, String>(
            description: "First: always matches"
        ) { (_: Draft) async in
            "FirstMatch"
        }

        let secondDecision = AsyncDecisionEntry<Draft, String>(
            description: "Second: also matches"
        ) { (_: Draft) async in
            "SecondMatch"
        }

        let asyncDecisionBinding = AsyncDecisionBinding(
            key: "pet.name",
            keyPath: \Draft.petName,
            decisions: [firstDecision, secondDecision]
        )

        let profile = SpecProfile(
            bindings: [AnyBinding(sleepingBinding)],
            asyncDecisionBindings: [AnyAsyncDecisionBinding(asyncDecisionBinding)],
            finalize: { draft in
                guard let petName = draft.petName else {
                    throw TestError.missingName
                }
                guard let isSleeping = draft.isSleeping else {
                    throw TestError.missingSleepFlag
                }
                return Config(petName: petName, isSleeping: isSleeping)
            },
            makeDraft: { Draft() }
        )

        let provider = InMemoryProvider(values: [
            "pet.isSleeping": true,
        ])
        let reader = ConfigReader(provider: provider)

        let result = await ConfigPipeline.buildAsync(profile: profile, reader: reader)

        switch result {
        case let .success(config, snapshot):
            XCTAssertEqual(config.petName, "FirstMatch")
            let trace = snapshot.decisionTrace(forKey: "pet.name")
            XCTAssertEqual(trace?.matchedIndex, 0)
            XCTAssertEqual(trace?.decisionName, "First: always matches")
        case .failure:
            XCTFail("Expected first async decision to match")
        }
    }
}
