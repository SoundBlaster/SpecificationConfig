import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

final class AnyBindingTests: XCTestCase {
    // Test Draft type
    struct TestDraft {
        var name: String?
        var age: Int?
        var isActive: Bool?
        var url: URL?
    }

    // Helper to create a ConfigReader for testing
    func makeReader(values: [AbsoluteConfigKey: ConfigValue] = [:]) -> ConfigReader {
        let provider = InMemoryProvider(values: values)
        return ConfigReader(provider: provider)
    }

    func testAnyBindingCreation() {
        // Test that we can create AnyBinding from Binding
        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "Test" }
        )

        let anyBinding = AnyBinding(binding)

        XCTAssertEqual(anyBinding.key, "user.name")
    }

    func testKeyPreservation() {
        // Test that key is preserved through type erasure
        let binding = Binding<TestDraft, Int>(
            key: "user.age",
            keyPath: \TestDraft.age,
            decoder: { _, _ in 25 }
        )

        let anyBinding = AnyBinding(binding)

        XCTAssertEqual(anyBinding.key, "user.age")
        XCTAssertEqual(anyBinding.key, binding.key)
    }

    func testApplyWritesToDraft() throws {
        // Test that apply successfully writes to draft
        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "Alice" }
        )

        let anyBinding = AnyBinding(binding)
        var draft = TestDraft()
        let reader = makeReader()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.name, "Alice")
    }

    func testApplyWithDefaultValue() throws {
        // Test that apply uses default when decoder returns nil
        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in nil }, // Decoder returns nil
            defaultValue: "DefaultName"
        )

        let anyBinding = AnyBinding(binding)
        var draft = TestDraft()
        let reader = makeReader()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.name, "DefaultName")
    }

    func testApplyWithMissingKeyNoDefault() throws {
        // Test that apply leaves field nil when no value and no default
        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in nil } // No value
            // No default
        )

        let anyBinding = AnyBinding(binding)
        var draft = TestDraft()
        let reader = makeReader()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertNil(draft.name)
    }

    func testHeterogeneousCollection() throws {
        // Test that we can store different Value types in a single array
        let nameBinding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "Bob" }
        )

        let ageBinding = Binding<TestDraft, Int>(
            key: "user.age",
            keyPath: \TestDraft.age,
            decoder: { _, _ in 30 }
        )

        let activeBinding = Binding<TestDraft, Bool>(
            key: "user.active",
            keyPath: \TestDraft.isActive,
            decoder: { _, _ in true }
        )

        // Store in homogeneous array
        let bindings: [AnyBinding<TestDraft>] = [
            AnyBinding(nameBinding),
            AnyBinding(ageBinding),
            AnyBinding(activeBinding),
        ]

        XCTAssertEqual(bindings.count, 3)
        XCTAssertEqual(bindings[0].key, "user.name")
        XCTAssertEqual(bindings[1].key, "user.age")
        XCTAssertEqual(bindings[2].key, "user.active")

        // Apply all bindings
        var draft = TestDraft()
        let reader = makeReader()

        for binding in bindings {
            try binding.apply(to: &draft, reader: reader)
        }

        XCTAssertEqual(draft.name, "Bob")
        XCTAssertEqual(draft.age, 30)
        XCTAssertEqual(draft.isActive, true)
    }

    func testApplyWithDecoderError() {
        // Test that decoder errors are propagated
        enum TestError: Error {
            case decodeFailed
        }

        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in
                throw TestError.decodeFailed
            }
        )

        let anyBinding = AnyBinding(binding)
        var draft = TestDraft()
        let reader = makeReader()

        XCTAssertThrowsError(try anyBinding.apply(to: &draft, reader: reader)) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testApplyWithSpecValidation() throws {
        // Test that spec validation is run
        // Note: This is a simplified test since we can't easily create custom specs
        // Full spec validation will be tested in integration tests

        let binding = Binding<TestDraft, String>(
            key: "user.name",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "ValidName" },
            valueSpecs: [] // Empty specs (all pass)
        )

        let anyBinding = AnyBinding(binding)
        var draft = TestDraft()
        let reader = makeReader()

        try anyBinding.apply(to: &draft, reader: reader)

        XCTAssertEqual(draft.name, "ValidName")
    }

    func testMultipleBindingsSameField() throws {
        // Test that last write wins when multiple bindings target same field
        let binding1 = Binding<TestDraft, String>(
            key: "name1",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "First" }
        )

        let binding2 = Binding<TestDraft, String>(
            key: "name2",
            keyPath: \TestDraft.name,
            decoder: { _, _ in "Second" }
        )

        let bindings = [AnyBinding(binding1), AnyBinding(binding2)]

        var draft = TestDraft()
        let reader = makeReader()

        for binding in bindings {
            try binding.apply(to: &draft, reader: reader)
        }

        XCTAssertEqual(draft.name, "Second") // Last write wins
    }
}
