import Foundation
@testable import SpecificationConfig
import XCTest

final class SnapshotTests: XCTestCase {
    // MARK: - Provenance Tests

    func testProvenanceEquality() {
        // Test file provider equality
        let file1 = Provenance.fileProvider(name: "config.json")
        let file2 = Provenance.fileProvider(name: "config.json")
        let file3 = Provenance.fileProvider(name: "other.json")

        XCTAssertEqual(file1, file2)
        XCTAssertNotEqual(file1, file3)

        // Test environment variable
        let env1 = Provenance.environmentVariable
        let env2 = Provenance.environmentVariable
        XCTAssertEqual(env1, env2)

        // Test default value
        let default1 = Provenance.defaultValue
        let default2 = Provenance.defaultValue
        XCTAssertEqual(default1, default2)

        // Test unknown
        let unknown1 = Provenance.unknown
        let unknown2 = Provenance.unknown
        XCTAssertEqual(unknown1, unknown2)

        // Test different types not equal
        XCTAssertNotEqual(env1, default1)
        XCTAssertNotEqual(file1, env1)
    }

    func testProvenanceCases() {
        // Verify all four cases exist and are distinct
        let file = Provenance.fileProvider(name: "test.json")
        let env = Provenance.environmentVariable
        let defaultVal = Provenance.defaultValue
        let unknown = Provenance.unknown

        // Each should be distinct
        XCTAssertNotEqual(file, env)
        XCTAssertNotEqual(file, defaultVal)
        XCTAssertNotEqual(file, unknown)
        XCTAssertNotEqual(env, defaultVal)
        XCTAssertNotEqual(env, unknown)
        XCTAssertNotEqual(defaultVal, unknown)
    }

    // MARK: - ResolvedValue Tests

    func testResolvedValueCreation() {
        let value = ResolvedValue(
            key: "app.name",
            stringifiedValue: "MyApp",
            provenance: .fileProvider(name: "config.json"),
            isSecret: false
        )

        XCTAssertEqual(value.key, "app.name")
        XCTAssertEqual(value.stringifiedValue, "MyApp")
        XCTAssertEqual(value.provenance, .fileProvider(name: "config.json"))
        XCTAssertFalse(value.isSecret)
    }

    func testResolvedValueRedaction() {
        // Non-secret value shows actual value
        let publicValue = ResolvedValue(
            key: "app.name",
            stringifiedValue: "MyApp",
            provenance: .fileProvider(name: "config.json"),
            isSecret: false
        )
        XCTAssertEqual(publicValue.displayValue, "MyApp")

        // Secret value shows redacted
        let secretValue = ResolvedValue(
            key: "api.key",
            stringifiedValue: "secret123",
            provenance: .environmentVariable,
            isSecret: true
        )
        XCTAssertEqual(secretValue.displayValue, "[REDACTED]")
        XCTAssertEqual(secretValue.stringifiedValue, "secret123") // Original still accessible
    }

    func testResolvedValueDefaultIsSecret() {
        // isSecret should default to false
        let value = ResolvedValue(
            key: "test",
            stringifiedValue: "value",
            provenance: .unknown
        )
        XCTAssertFalse(value.isSecret)
        XCTAssertEqual(value.displayValue, "value")
    }

    func testResolvedValueEquality() {
        let value1 = ResolvedValue(
            key: "test",
            stringifiedValue: "value",
            provenance: .defaultValue,
            isSecret: false
        )

        let value2 = ResolvedValue(
            key: "test",
            stringifiedValue: "value",
            provenance: .defaultValue,
            isSecret: false
        )

        let value3 = ResolvedValue(
            key: "test",
            stringifiedValue: "different",
            provenance: .defaultValue,
            isSecret: false
        )

        XCTAssertEqual(value1, value2)
        XCTAssertNotEqual(value1, value3)
    }

    // MARK: - Snapshot Tests

    func testSnapshotCreation() {
        // Test empty snapshot with defaults
        let emptySnapshot = Snapshot()
        XCTAssertTrue(emptySnapshot.resolvedValues.isEmpty)
        XCTAssertTrue(emptySnapshot.diagnostics.isEmpty)
        XCTAssertFalse(emptySnapshot.hasErrors)

        // Test snapshot with values
        let values = [
            ResolvedValue(
                key: "app.name",
                stringifiedValue: "MyApp",
                provenance: .fileProvider(name: "config.json")
            ),
        ]

        let snapshot = Snapshot(
            resolvedValues: values,
            diagnostics: DiagnosticsReport()
        )

        XCTAssertEqual(snapshot.resolvedValues.count, 1)
        XCTAssertEqual(snapshot.resolvedValues[0].key, "app.name")
    }

    func testSnapshotValueLookup() {
        let values = [
            ResolvedValue(
                key: "app.name",
                stringifiedValue: "MyApp",
                provenance: .fileProvider(name: "config.json")
            ),
            ResolvedValue(
                key: "app.port",
                stringifiedValue: "8080",
                provenance: .environmentVariable
            ),
            ResolvedValue(
                key: "api.key",
                stringifiedValue: "secret",
                provenance: .environmentVariable,
                isSecret: true
            ),
        ]

        let snapshot = Snapshot(resolvedValues: values)

        // Lookup existing key
        let name = snapshot.value(forKey: "app.name")
        XCTAssertNotNil(name)
        XCTAssertEqual(name?.stringifiedValue, "MyApp")
        XCTAssertEqual(name?.provenance, .fileProvider(name: "config.json"))

        // Lookup another key
        let port = snapshot.value(forKey: "app.port")
        XCTAssertNotNil(port)
        XCTAssertEqual(port?.stringifiedValue, "8080")

        // Lookup non-existent key
        let missing = snapshot.value(forKey: "does.not.exist")
        XCTAssertNil(missing)
    }

    func testSnapshotTimestamp() {
        let before = Date()
        let snapshot = Snapshot()
        let after = Date()

        // Timestamp should be between before and after (within 1 second window)
        XCTAssertGreaterThanOrEqual(snapshot.timestamp, before.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(snapshot.timestamp, after.addingTimeInterval(1))
    }

    func testSnapshotHasErrors() {
        // Empty diagnostics = no errors
        let cleanSnapshot = Snapshot(diagnostics: DiagnosticsReport())
        XCTAssertFalse(cleanSnapshot.hasErrors)

        // With diagnostics = has errors
        var errorReport = DiagnosticsReport()
        errorReport.add(key: "missing.key", severity: .error, message: "Missing required key")
        let errorSnapshot = Snapshot(diagnostics: errorReport)
        XCTAssertTrue(errorSnapshot.hasErrors)

        // Multiple diagnostics
        var multiReport = DiagnosticsReport()
        multiReport.add(key: "error.one", severity: .error, message: "Error 1")
        multiReport.add(key: "error.two", severity: .error, message: "Error 2")
        multiReport.add(key: "warn.one", severity: .warning, message: "Warning 1")
        let multiErrorSnapshot = Snapshot(diagnostics: multiReport)
        XCTAssertTrue(multiErrorSnapshot.hasErrors)
    }

    func testSnapshotMultipleProvenanceSources() {
        let values = [
            ResolvedValue(
                key: "from.file",
                stringifiedValue: "file-value",
                provenance: .fileProvider(name: "config.json")
            ),
            ResolvedValue(
                key: "from.env",
                stringifiedValue: "env-value",
                provenance: .environmentVariable
            ),
            ResolvedValue(
                key: "from.default",
                stringifiedValue: "default-value",
                provenance: .defaultValue
            ),
            ResolvedValue(
                key: "from.unknown",
                stringifiedValue: "unknown-value",
                provenance: .unknown
            ),
        ]

        let snapshot = Snapshot(resolvedValues: values)

        // Verify each provenance is tracked correctly
        XCTAssertEqual(
            snapshot.value(forKey: "from.file")?.provenance,
            .fileProvider(name: "config.json")
        )
        XCTAssertEqual(
            snapshot.value(forKey: "from.env")?.provenance,
            .environmentVariable
        )
        XCTAssertEqual(
            snapshot.value(forKey: "from.default")?.provenance,
            .defaultValue
        )
        XCTAssertEqual(
            snapshot.value(forKey: "from.unknown")?.provenance,
            .unknown
        )
    }

    func testSnapshotWithSecretsAndNonSecrets() {
        let values = [
            ResolvedValue(
                key: "public.value",
                stringifiedValue: "visible",
                provenance: .fileProvider(name: "config.json"),
                isSecret: false
            ),
            ResolvedValue(
                key: "secret.key",
                stringifiedValue: "hidden123",
                provenance: .environmentVariable,
                isSecret: true
            ),
        ]

        let snapshot = Snapshot(resolvedValues: values)

        let publicVal = snapshot.value(forKey: "public.value")
        XCTAssertEqual(publicVal?.displayValue, "visible")

        let secretVal = snapshot.value(forKey: "secret.key")
        XCTAssertEqual(secretVal?.displayValue, "[REDACTED]")
        XCTAssertEqual(secretVal?.stringifiedValue, "hidden123")
    }

    func testSnapshotCustomTimestamp() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let snapshot = Snapshot(
            resolvedValues: [],
            timestamp: customDate,
            diagnostics: DiagnosticsReport()
        )

        XCTAssertEqual(snapshot.timestamp, customDate)
    }
}
