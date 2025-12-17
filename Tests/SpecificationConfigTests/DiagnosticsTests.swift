@testable import SpecificationConfig
import XCTest

final class DiagnosticsTests: XCTestCase {
    func testSeverityOrdering() {
        XCTAssertLessThan(DiagnosticSeverity.error, .warning)
        XCTAssertLessThan(DiagnosticSeverity.warning, .info)
        XCTAssertLessThan(DiagnosticSeverity.error, .info)
    }

    func testDiagnosticItemCreationWithContextAndRedaction() {
        let item = DiagnosticItem(
            key: "api.key",
            severity: .error,
            message: "Invalid API key: sk_live_123",
            isMessageRedacted: true,
            context: [
                "source": DiagnosticContextValue("environment"),
                "value": DiagnosticContextValue("sk_live_123", isSecret: true),
            ]
        )

        XCTAssertEqual(item.key, "api.key")
        XCTAssertEqual(item.severity, .error)
        XCTAssertEqual(item.displayMessage, "[REDACTED]")
        XCTAssertEqual(item.context["source"]?.displayValue, "environment")
        XCTAssertEqual(item.context["value"]?.displayValue, "[REDACTED]")
        XCTAssertTrue(item.formattedDescription().contains("[REDACTED]"))
    }

    func testDiagnosticsReportAddAndCounts() {
        var report = DiagnosticsReport()
        XCTAssertTrue(report.isEmpty)
        XCTAssertEqual(report.count, 0)
        XCTAssertFalse(report.hasErrors)
        XCTAssertFalse(report.hasWarnings)

        report.add(key: "db.host", severity: .error, message: "Missing host")
        report.add(key: "db.port", severity: .warning, message: "Using default port")
        report.add(key: "app.name", severity: .info, message: "Default app name")

        XCTAssertEqual(report.count, 3)
        XCTAssertTrue(report.hasErrors)
        XCTAssertTrue(report.hasWarnings)
        XCTAssertEqual(report.errorCount, 1)
        XCTAssertEqual(report.warningCount, 1)
        XCTAssertEqual(report.infoCount, 1)
    }

    func testDiagnosticsReportMerge() {
        var first = DiagnosticsReport()
        first.add(key: "first", severity: .error, message: "First error")

        var second = DiagnosticsReport()
        second.add(key: "second", severity: .warning, message: "Second warning")

        first.merge(second)
        XCTAssertEqual(first.count, 2)
        XCTAssertTrue(first.hasWarnings)
        XCTAssertTrue(first.hasErrors)
    }

    func testDiagnosticsOrderedByKeySeverityAndMessage() {
        var report = DiagnosticsReport()
        report.add(key: "b", severity: .error, message: "Beta error")
        report.add(key: "a", severity: .warning, message: "Alpha warning")
        report.add(key: "a", severity: .error, message: "Alpha error")
        report.add(key: nil, severity: .info, message: "No key info")

        let ordered = report.diagnostics
        XCTAssertEqual(ordered[0].key, "a")
        XCTAssertEqual(ordered[0].severity, .error)
        XCTAssertEqual(ordered[1].severity, .warning)
        XCTAssertEqual(ordered[2].key, "b")
        XCTAssertNil(ordered.last?.key)
    }

    func testDiagnosticsOrderedByDisplayMessageWhenKeysAndSeveritiesMatch() {
        var report = DiagnosticsReport()
        report.add(
            key: "alpha",
            severity: .error,
            message: "zzz message",
            context: ["foo": DiagnosticContextValue("bar")]
        )
        report.add(
            key: "alpha",
            severity: .error,
            message: "aaa message",
            context: ["foo": DiagnosticContextValue("baz")]
        )

        let ordered = report.diagnostics
        XCTAssertEqual(ordered[0].message, "aaa message")
        XCTAssertEqual(ordered[1].message, "zzz message")
    }

    func testDeterministicOrderingAcrossReports() {
        func makeReport() -> DiagnosticsReport {
            var report = DiagnosticsReport()
            report.add(key: "z", severity: .warning, message: "Last")
            report.add(key: "a", severity: .error, message: "First error")
            report.add(key: nil, severity: .info, message: "No key info")
            report.add(key: "a", severity: .warning, message: "First warning")
            report.add(key: "m", severity: .error, message: "Middle")
            return report
        }

        let first = makeReport()
        let second = makeReport()
        XCTAssertEqual(first.diagnostics, second.diagnostics)
    }

    func testFormattedDescriptionIncludesContext() {
        let item = DiagnosticItem(
            key: "db.password",
            severity: .warning,
            message: "Using default password",
            context: [
                "provider": DiagnosticContextValue("file"),
                "value": DiagnosticContextValue("secret-pass", isSecret: true),
            ]
        )

        let description = item.formattedDescription()
        XCTAssertTrue(description.contains("provider=file"))
        XCTAssertTrue(description.contains("value=[REDACTED]"))
    }
}
