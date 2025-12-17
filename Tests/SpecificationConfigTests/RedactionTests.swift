@testable import SpecificationConfig
import XCTest

/// Tests for the Redaction utilities that ensure sensitive values are properly redacted.
final class RedactionTests: XCTestCase {
    // MARK: - Redaction Marker Tests

    func testRedactionMarkerValue() {
        XCTAssertEqual(Redaction.marker, "[REDACTED]")
    }

    // MARK: - Non-Optional String Redaction Tests

    func testRedactPublicValue() {
        let result = Redaction.redact("public-data", isSecret: false)
        XCTAssertEqual(result, "public-data")
    }

    func testRedactSecretValue() {
        let result = Redaction.redact("secret-api-key", isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactEmptyStringPublic() {
        let result = Redaction.redact("", isSecret: false)
        XCTAssertEqual(result, "")
    }

    func testRedactEmptyStringSecret() {
        let result = Redaction.redact("", isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactUnicodeValue() {
        let result = Redaction.redact("🔑 secret-key 密钥", isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactWhitespaceOnlyPublic() {
        let result = Redaction.redact("   ", isSecret: false)
        XCTAssertEqual(result, "   ")
    }

    func testRedactWhitespaceOnlySecret() {
        let result = Redaction.redact("   ", isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactMultilineStringSecret() {
        let result = Redaction.redact("line1\nline2\nline3", isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactVeryLongStringSecret() {
        let longString = String(repeating: "a", count: 10000)
        let result = Redaction.redact(longString, isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    // MARK: - Optional String Redaction Tests

    func testRedactOptionalNilPublic() {
        let value: String? = nil
        let result = Redaction.redact(value, isSecret: false)
        XCTAssertNil(result)
    }

    func testRedactOptionalNilSecret() {
        let value: String? = nil
        let result = Redaction.redact(value, isSecret: true)
        XCTAssertNil(result)
    }

    func testRedactOptionalPublic() {
        let value: String? = "public"
        let result = Redaction.redact(value, isSecret: false)
        XCTAssertEqual(result, "public")
    }

    func testRedactOptionalSecret() {
        let value: String? = "secret"
        let result = Redaction.redact(value, isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    func testRedactOptionalEmptyStringSecret() {
        let value: String? = ""
        let result = Redaction.redact(value, isSecret: true)
        XCTAssertEqual(result, "[REDACTED]")
    }

    // MARK: - Consistency Tests

    func testRedactConsistentBehaviorBetweenOptionalAndNonOptional() {
        let nonOptionalSecret = Redaction.redact("test", isSecret: true)
        let optionalSecret = Redaction.redact(Optional("test"), isSecret: true)

        XCTAssertEqual(nonOptionalSecret, optionalSecret)
        XCTAssertEqual(nonOptionalSecret, "[REDACTED]")
    }

    func testRedactConsistentBehaviorForPublicValues() {
        let nonOptionalPublic = Redaction.redact("test", isSecret: false)
        let optionalPublic = Redaction.redact(Optional("test"), isSecret: false)

        XCTAssertEqual(nonOptionalPublic, optionalPublic)
        XCTAssertEqual(nonOptionalPublic, "test")
    }
}
