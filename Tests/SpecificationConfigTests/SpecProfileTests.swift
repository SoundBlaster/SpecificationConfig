import Configuration
@testable import SpecificationConfig
import SpecificationCore
import XCTest

final class SpecProfileTests: XCTestCase {
    private struct Draft {
        var name: String?
        var port: Int?
        var flags: [String]?
    }

    private struct AppConfig: Equatable {
        let name: String
        let port: Int
    }

    private enum TestError: Error {
        case missingValue
    }

    private func makeReader(values: [AbsoluteConfigKey: ConfigValue] = [:]) -> ConfigReader {
        let provider = InMemoryProvider(values: values)
        return ConfigReader(provider: provider)
    }

    func testBuildAppliesBindingsAndFinalizes() throws {
        let values: [AbsoluteConfigKey: ConfigValue] = [
            "app.name": "Pet App",
            "app.port": 8080,
        ]

        let nameBinding = Binding<Draft, String>(
            key: "app.name",
            keyPath: \Draft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
        )

        let portBinding = Binding<Draft, Int>(
            key: "app.port",
            keyPath: \Draft.port,
            decoder: { reader, key in reader.int(forKey: ConfigKey(key)) }
        )

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [AnyBinding(nameBinding), AnyBinding(portBinding)],
            finalize: { draft in
                guard let name = draft.name, let port = draft.port else {
                    throw TestError.missingValue
                }
                return AppConfig(name: name, port: port)
            },
            finalSpecs: [
                SpecEntry(PredicateSpec<AppConfig>(description: "Port > 0") { $0.port > 0 }),
            ],
            makeDraft: { Draft() }
        )

        let finalConfig = try profile.build(reader: makeReader(values: values))

        XCTAssertEqual(finalConfig, AppConfig(name: "Pet App", port: 8080))
    }

    func testBuildPropagatesValueSpecFailure() {
        let values: [AbsoluteConfigKey: ConfigValue] = [
            "feature.name": "",
        ]

        let nameBinding = Binding<Draft, String>(
            key: "feature.name",
            keyPath: \Draft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            valueSpecs: [
                SpecEntry(PredicateSpec<String>(description: "Non-empty") { !$0.isEmpty }),
            ]
        )

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingValue }
                return AppConfig(name: name, port: 0)
            },
            makeDraft: { Draft() }
        )

        XCTAssertThrowsError(try profile.applyBindings(reader: makeReader(values: values))) { error in
            guard case let ConfigError.specFailed(key, spec)? = error as? ConfigError else {
                return XCTFail("Expected ConfigError.specFailed")
            }
            XCTAssertEqual(key, "feature.name")
            XCTAssertEqual(spec.displayName, "Non-empty")
        }
    }

    func testContextualValueSpecUsesContextProvider() throws {
        let values: [AbsoluteConfigKey: ConfigValue] = [
            "feature.name": "Enabled",
        ]
        let context = EvaluationContext(flags: ["featureEnabled": true])
        let provider = AnyContextProvider(StaticContextProvider(context))

        let nameBinding = Binding<Draft, String>(
            key: "feature.name",
            keyPath: \Draft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            contextualValueSpecs: [
                ContextualSpecEntry(description: "Feature enabled") { context, _ in
                    context.flag(for: "featureEnabled")
                },
            ]
        )

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [AnyBinding(nameBinding)],
            contextProvider: provider,
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingValue }
                return AppConfig(name: name, port: 0)
            },
            makeDraft: { Draft() }
        )

        _ = try profile.applyBindings(reader: makeReader(values: values))
    }

    func testContextualValueSpecRequiresProvider() {
        let values: [AbsoluteConfigKey: ConfigValue] = [
            "feature.name": "Enabled",
        ]

        let nameBinding = Binding<Draft, String>(
            key: "feature.name",
            keyPath: \Draft.name,
            decoder: { reader, key in reader.string(forKey: ConfigKey(key)) },
            contextualValueSpecs: [
                ContextualSpecEntry(description: "Feature enabled") { context, _ in
                    context.flag(for: "featureEnabled")
                },
            ]
        )

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [AnyBinding(nameBinding)],
            finalize: { draft in
                guard let name = draft.name else { throw TestError.missingValue }
                return AppConfig(name: name, port: 0)
            },
            makeDraft: { Draft() }
        )

        XCTAssertThrowsError(try profile.applyBindings(reader: makeReader(values: values))) { error in
            guard case let ConfigError.contextProviderMissing(key)? = error as? ConfigError else {
                return XCTFail("Expected ConfigError.contextProviderMissing")
            }
            XCTAssertEqual(key, "feature.name")
        }
    }

    func testFinalizeDraftRunsFinalSpecs() throws {
        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [],
            finalize: { _ in AppConfig(name: "Invalid", port: -1) },
            finalSpecs: [
                SpecEntry(PredicateSpec<AppConfig>(description: "Port > 0") { $0.port > 0 }),
            ],
            makeDraft: { Draft() }
        )

        XCTAssertThrowsError(try profile.finalizeDraft(Draft())) { error in
            guard case let ConfigError.finalSpecFailed(spec)? = error as? ConfigError else {
                return XCTFail("Expected ConfigError.finalSpecFailed")
            }
            XCTAssertEqual(spec.displayName, "Port > 0")
        }
    }

    func testFinalizeDraftRunsContextualFinalSpecs() {
        let context = EvaluationContext(flags: ["featureEnabled": false])
        let provider = AnyContextProvider(StaticContextProvider(context))

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [],
            contextProvider: provider,
            finalize: { _ in AppConfig(name: "Name", port: 0) },
            contextualFinalSpecs: [
                ContextualSpecEntry(description: "Feature enabled") { context, _ in
                    context.flag(for: "featureEnabled")
                },
            ],
            makeDraft: { Draft() }
        )

        XCTAssertThrowsError(try profile.finalizeDraft(Draft())) { error in
            guard case let ConfigError.finalSpecFailed(spec)? = error as? ConfigError else {
                return XCTFail("Expected ConfigError.finalSpecFailed")
            }
            XCTAssertEqual(spec.displayName, "Feature enabled")
        }
    }

    func testBindingsAreAppliedInDeclaredOrder() throws {
        var applicationOrder: [String] = []

        let first = Binding<Draft, String>(
            key: "first",
            keyPath: \Draft.name,
            decoder: { _, key in
                applicationOrder.append(key)
                return "first"
            }
        )

        let second = Binding<Draft, Int>(
            key: "second",
            keyPath: \Draft.port,
            decoder: { _, key in
                applicationOrder.append(key)
                return 2
            }
        )

        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [AnyBinding(first), AnyBinding(second)],
            finalize: { draft in
                AppConfig(name: draft.name ?? "", port: draft.port ?? 0)
            },
            makeDraft: { Draft() }
        )

        _ = try profile.applyBindings(reader: makeReader())

        XCTAssertEqual(applicationOrder, ["first", "second"])
    }
}
