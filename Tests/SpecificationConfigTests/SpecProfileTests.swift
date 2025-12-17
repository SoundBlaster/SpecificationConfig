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
            finalSpecs: [AnySpecification<AppConfig> { $0.port > 0 }],
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
            valueSpecs: [AnySpecification<String> { !$0.isEmpty }]
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
            guard case let ConfigError.specFailed(key)? = error as? ConfigError else {
                return XCTFail("Expected ConfigError.specFailed")
            }
            XCTAssertEqual(key, "feature.name")
        }
    }

    func testFinalizeDraftRunsFinalSpecs() throws {
        let profile = SpecProfile<Draft, AppConfig>(
            bindings: [],
            finalize: { _ in AppConfig(name: "Invalid", port: -1) },
            finalSpecs: [AnySpecification<AppConfig> { $0.port > 0 }],
            makeDraft: { Draft() }
        )

        XCTAssertThrowsError(try profile.finalizeDraft(Draft())) { error in
            XCTAssertEqual(error as? ConfigError, .finalSpecFailed)
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
