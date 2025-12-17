# Task PRD: B5 — Add Redaction Support

**Task ID:** B5
**Task Name:** Add Redaction Support
**Priority:** Medium
**Effort:** M (½–1d)
**Dependencies:** B4 (assumed conceptually complete; B1, B3 already implemented)
**Phase:** B
**Status:** Ready for implementation

---

## 1. Scope and Intent

### 1.1 Objective

Create a formal, centralized redaction system to ensure sensitive configuration values (secrets) are properly and consistently redacted across all diagnostics, snapshots, logs, and error messages.

**Current state:**
- B1 (`Binding.swift`): Defines `isSecret: Bool` property
- B3 (`Snapshot.swift`): Implements `ResolvedValue.displayValue` with hardcoded `"[REDACTED]"` string
- Tests verify basic redaction behavior

**This task will:**
1. Create `Sources/SpecificationConfig/Redaction.swift` with formal redaction types and utilities
2. Standardize the redaction marker (currently hardcoded `"[REDACTED]"`)
3. Provide helper functions for consistent redaction across the codebase
4. Document best practices for handling secrets
5. Add comprehensive tests for all redaction scenarios
6. Refactor existing code to use the centralized redaction system

### 1.2 Primary Deliverables

| Deliverable | Type | Description | Success Criteria |
|---|---|---|---|
| `Redaction.swift` | Swift source file | Core redaction types and utilities | Compiles; public API documented |
| Refactored `Snapshot.swift` | Swift source file | Uses centralized redaction | Tests pass; no hardcoded markers |
| Comprehensive tests | XCTest | Unit tests for redaction scenarios | CI green; covers edge cases |
| Documentation | DocC comments | Best practices for secret handling | Clear, actionable guidance |

### 1.3 Success Criteria

- ✅ `Redaction.swift` exists in `Sources/SpecificationConfig/`
- ✅ Redaction marker is defined as a single constant/type
- ✅ `Snapshot.swift` uses centralized redaction utilities
- ✅ All tests pass: `swift build -v && swift test -v`
- ✅ SwiftFormat passes: `swiftformat --lint .`
- ✅ Documentation clearly explains when and how to mark values as secret

### 1.4 Non-Goals

- No encryption or cryptographic operations
- No actual secret management or vault integration
- No runtime detection of secret values (explicit marking only)
- No breaking changes to existing public API

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR-1: Centralized Redaction Marker
**Description:** Define a single, application-wide constant for the redaction marker.

**Acceptance Criteria:**
- Marker is defined as `public static let marker: String = "[REDACTED]"`
- All code uses this constant instead of hardcoded strings
- Marker is documented with usage examples

#### FR-2: Redaction Helper Functions
**Description:** Provide utility functions for redacting string values.

**Acceptance Criteria:**
- Function signature: `public static func redact(_ value: String, isSecret: Bool) -> String`
- Returns marker for secrets, original value otherwise
- Works with all String types (including empty strings)

#### FR-3: Consistent Redaction Across Types
**Description:** Ensure all types that display values use centralized redaction.

**Acceptance Criteria:**
- `ResolvedValue.displayValue` uses `Redaction.redact()`
- Future diagnostic types can easily integrate redaction
- No hardcoded redaction markers remain in codebase

#### FR-4: Documentation and Best Practices
**Description:** Document when and how to mark configuration values as secret.

**Acceptance Criteria:**
- DocC comments explain secret vs non-secret classification
- Examples show proper usage of `isSecret` flag
- Guidelines for common secret types (API keys, passwords, tokens)

### 2.2 Non-Functional Requirements

#### NFR-1: Performance
- Redaction operations must be O(1)
- No dynamic allocation for non-secret values
- Minimal overhead when redaction is not needed

#### NFR-2: Type Safety
- Use Swift type system to prevent misuse
- Clear, compile-time API
- No stringly-typed configuration

#### NFR-3: Testability
- All redaction logic is unit-testable
- Mock-friendly design
- Deterministic output

#### NFR-4: Consistency
- Single source of truth for redaction behavior
- Same marker across all subsystems
- Predictable behavior in all contexts

---

## 3. Technical Design

### 3.1 File Structure

```
Sources/SpecificationConfig/
  Redaction.swift          ← NEW (this task)
  Binding.swift            ← No changes (already has isSecret)
  Snapshot.swift           ← REFACTOR (use Redaction utilities)
  AnyBinding.swift         ← No changes (may use in future)
  SpecificationConfig.swift ← No changes

Tests/SpecificationConfigTests/
  RedactionTests.swift     ← NEW (comprehensive tests)
  SnapshotTests.swift      ← UPDATE (verify refactored code)
```

### 3.2 API Design: Redaction.swift

```swift
import Foundation

/// Utilities for redacting sensitive configuration values.
///
/// Use this type to ensure secrets (API keys, passwords, tokens) are
/// consistently hidden in logs, diagnostics, snapshots, and error messages.
///
/// ## Usage
///
/// Mark sensitive bindings with `isSecret: true`:
///
/// ```swift
/// let apiKeyBinding = Binding(
///     key: "api.secret_key",
///     keyPath: \Draft.apiKey,
///     decoder: { reader, key in try reader.get(key) },
///     isSecret: true  // This value will be redacted
/// )
/// ```
///
/// When displaying values, use `Redaction.redact()`:
///
/// ```swift
/// let display = Redaction.redact(apiKey, isSecret: true)
/// print(display) // "[REDACTED]"
/// ```
///
/// ## Best Practices
///
/// **Always mark as secret:**
/// - API keys and tokens
/// - Passwords and passphrases
/// - Private keys and certificates
/// - OAuth client secrets
/// - Database credentials
/// - Encryption keys
///
/// **Usually safe as public:**
/// - Application names
/// - Feature flags (boolean toggles)
/// - Numeric timeouts and limits
/// - Public URLs (without tokens in query strings)
/// - Log levels and debug flags
///
/// **Context-dependent:**
/// - Usernames (may be public or private)
/// - Email addresses (depends on privacy policy)
/// - Server hostnames (may reveal internal infrastructure)
///
/// When in doubt, mark as secret. It's safer to over-redact than to leak secrets.
public enum Redaction {
    /// The standard redaction marker.
    ///
    /// This string replaces secret values in all user-facing output:
    /// logs, diagnostics, snapshots, UI displays, and error messages.
    public static let marker: String = "[REDACTED]"

    /// Redacts a string value if marked as secret.
    ///
    /// - Parameters:
    ///   - value: The string value to potentially redact
    ///   - isSecret: Whether this value should be redacted
    /// - Returns: The redaction marker if secret, otherwise the original value
    ///
    /// ## Example
    ///
    /// ```swift
    /// let publicValue = Redaction.redact("https://api.example.com", isSecret: false)
    /// print(publicValue) // "https://api.example.com"
    ///
    /// let secretValue = Redaction.redact("sk_live_abc123", isSecret: true)
    /// print(secretValue) // "[REDACTED]"
    /// ```
    public static func redact(_ value: String, isSecret: Bool) -> String {
        isSecret ? marker : value
    }

    /// Redacts an optional string value if marked as secret.
    ///
    /// - Parameters:
    ///   - value: The optional string value to potentially redact
    ///   - isSecret: Whether this value should be redacted
    /// - Returns: The redaction marker if secret and non-nil, nil if value is nil, otherwise the original value
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = Redaction.redact(optionalPassword, isSecret: true)
    /// // Returns "[REDACTED]" if password exists, nil if it doesn't
    /// ```
    public static func redact(_ value: String?, isSecret: Bool) -> String? {
        guard let value else { return nil }
        return isSecret ? marker : value
    }
}
```

### 3.3 Refactoring: Snapshot.swift

**Change:** Update `ResolvedValue.displayValue` to use `Redaction.redact()`

```swift
// Before (line 70-72):
public var displayValue: String {
    isSecret ? "[REDACTED]" : stringifiedValue
}

// After:
public var displayValue: String {
    Redaction.redact(stringifiedValue, isSecret: isSecret)
}
```

**Note:** This is the only required change to existing code. The refactoring maintains identical behavior while centralizing the redaction logic.

---

## 4. Implementation Plan

### 4.1 Task Breakdown (Hierarchical TODO)

#### Phase 1: Create Redaction.swift (High Priority, 1-2h)
- [ ] **Task 1.1:** Create file `Sources/SpecificationConfig/Redaction.swift`
  - **Input:** API design from §3.2
  - **Output:** Compiling Swift file with public API
  - **Verification:** `swift build -v` succeeds
  - **Acceptance:** File exists and compiles without errors

- [ ] **Task 1.2:** Implement `Redaction` enum with marker constant
  - **Input:** Design specification
  - **Output:** Public static `marker` property
  - **Verification:** Can reference `Redaction.marker` from tests
  - **Acceptance:** Constant is accessible and has correct value

- [ ] **Task 1.3:** Implement `redact(_:isSecret:)` for String
  - **Input:** Function signature from §3.2
  - **Output:** Working redaction function for non-optional strings
  - **Verification:** Returns marker when `isSecret == true`, value when `false`
  - **Acceptance:** Function logic is correct and documented

- [ ] **Task 1.4:** Implement `redact(_:isSecret:)` for String?
  - **Input:** Function signature from §3.2
  - **Output:** Working redaction function for optional strings
  - **Verification:** Handles nil correctly, redacts when needed
  - **Acceptance:** Function handles all cases (nil, secret, public)

- [ ] **Task 1.5:** Add comprehensive DocC documentation
  - **Input:** Best practices from §3.2 comments
  - **Output:** Fully documented public API with examples
  - **Verification:** Documentation builds without warnings
  - **Acceptance:** All public members have clear, helpful documentation

#### Phase 2: Refactor Snapshot.swift (High Priority, 15-30min)
- [ ] **Task 2.1:** Update ResolvedValue.displayValue to use Redaction.redact()
  - **Input:** Current implementation (Snapshot.swift:70-72)
  - **Output:** Refactored implementation using centralized redaction
  - **Verification:** Existing tests still pass
  - **Acceptance:** No hardcoded "[REDACTED]" strings remain; behavior unchanged

- [ ] **Task 2.2:** Verify no other hardcoded redaction markers exist
  - **Input:** Full codebase
  - **Output:** Confirmation that all redaction uses Redaction.swift
  - **Verification:** Grep for `"[REDACTED]"` returns only Redaction.swift
  - **Acceptance:** Single source of truth for redaction marker

#### Phase 3: Add Comprehensive Tests (High Priority, 2-3h)
- [ ] **Task 3.1:** Create `Tests/SpecificationConfigTests/RedactionTests.swift`
  - **Input:** Test plan from §5
  - **Output:** New test file with test structure
  - **Verification:** File compiles and is discovered by test runner
  - **Acceptance:** Test file exists and imports necessary modules

- [ ] **Task 3.2:** Test redaction marker constant
  - **Input:** Redaction.marker
  - **Output:** Test verifying marker value
  - **Verification:** `swift test -v` passes
  - **Acceptance:** Test confirms marker is "[REDACTED]"

- [ ] **Task 3.3:** Test redact(_:isSecret:) with non-optional String
  - **Input:** Various string values and isSecret flags
  - **Output:** Tests covering all combinations
  - **Verification:** All test cases pass
  - **Acceptance:** Tests verify correct redaction and pass-through behavior

- [ ] **Task 3.4:** Test redact(_:isSecret:) with optional String
  - **Input:** nil and non-nil values with various isSecret flags
  - **Output:** Tests covering nil handling
  - **Verification:** All test cases pass
  - **Acceptance:** Tests verify nil propagation and redaction

- [ ] **Task 3.5:** Test edge cases (empty strings, special characters)
  - **Input:** Edge case values from §5.2
  - **Output:** Tests for boundary conditions
  - **Verification:** All edge cases handled correctly
  - **Acceptance:** Empty strings, Unicode, and special cases work correctly

- [ ] **Task 3.6:** Update SnapshotTests.swift
  - **Input:** Existing SnapshotTests.swift
  - **Output:** Tests verify refactored code still works
  - **Verification:** All existing snapshot tests pass
  - **Acceptance:** Refactoring didn't break existing functionality

#### Phase 4: Quality Assurance (High Priority, 30min)
- [ ] **Task 4.1:** Run full test suite
  - **Input:** All implemented code and tests
  - **Output:** Passing CI locally
  - **Verification:** `swift build -v && swift test -v` succeeds
  - **Acceptance:** Zero test failures, zero build errors

- [ ] **Task 4.2:** Run SwiftFormat lint
  - **Input:** All modified files
  - **Output:** Formatted code
  - **Verification:** `swiftformat --lint .` passes
  - **Acceptance:** No formatting issues reported

- [ ] **Task 4.3:** Run Thread Sanitizer
  - **Input:** Test suite
  - **Output:** Clean sanitizer run
  - **Verification:** `swift test --sanitize=thread` passes
  - **Acceptance:** No threading issues detected

- [ ] **Task 4.4:** Verify documentation completeness
  - **Input:** All public API in Redaction.swift
  - **Output:** Confirmation of complete documentation
  - **Verification:** Manual review of DocC comments
  - **Acceptance:** All public types, properties, and functions documented

---

## 5. Test Plan

### 5.1 Unit Tests (RedactionTests.swift)

#### Test Suite 1: Redaction Marker
```swift
func testRedactionMarkerValue() {
    XCTAssertEqual(Redaction.marker, "[REDACTED]")
}
```

#### Test Suite 2: Non-Optional String Redaction
```swift
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
```

#### Test Suite 3: Optional String Redaction
```swift
func testRedactOptionalNil() {
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
```

### 5.2 Edge Cases

| Scenario | Input | isSecret | Expected Output |
|---|---|---|---|
| Empty string (public) | `""` | false | `""` |
| Empty string (secret) | `""` | true | `"[REDACTED]"` |
| Whitespace only | `"   "` | true | `"[REDACTED]"` |
| Very long string | 10,000 chars | true | `"[REDACTED]"` |
| Unicode characters | `"🔐 key"` | true | `"[REDACTED]"` |
| Newlines in value | `"line1\nline2"` | true | `"[REDACTED]"` |
| Nil optional (secret) | `nil` | true | `nil` |
| Nil optional (public) | `nil` | false | `nil` |

### 5.3 Integration Tests (SnapshotTests.swift updates)

Verify existing tests continue to pass:
- `testResolvedValueRedaction()` - Should still pass after refactoring
- `testResolvedValueDefaultIsSecret()` - Should maintain same behavior
- All snapshot creation tests with secret values

---

## 6. Acceptance Criteria

### 6.1 Code Quality
- [ ] All code follows Swift API design guidelines
- [ ] SwiftFormat passes with zero warnings
- [ ] No compiler warnings
- [ ] No force-unwraps or unsafe constructs
- [ ] Code is Sendable-safe (no data races)

### 6.2 Testing
- [ ] Unit test coverage for all public API
- [ ] Edge cases are tested and documented
- [ ] Thread Sanitizer passes
- [ ] All tests are deterministic and repeatable

### 6.3 Documentation
- [ ] All public types have DocC comments
- [ ] Examples are provided for common use cases
- [ ] Best practices section is clear and actionable
- [ ] Comments explain "why" not just "what"

### 6.4 Integration
- [ ] Existing tests continue to pass
- [ ] No breaking changes to public API
- [ ] Refactored code maintains identical behavior
- [ ] CI pipeline passes on all jobs

---

## 7. Verification Commands

Run these commands in sequence to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests
swift test -v

# 3. Run thread sanitizer
swift test --sanitize=thread

# 4. Check code formatting (requires SwiftFormat)
swiftformat --lint .

# 5. Verify no hardcoded redaction markers outside Redaction.swift
grep -r "\[REDACTED\]" Sources/ Tests/ | grep -v "Redaction.swift" | grep -v ".build"
# Expected: No matches (or only in comments)

# 6. Build in release mode
swift build -c release
```

**Success criteria:** All commands complete without errors or warnings.

---

## 8. Definition of Done

This task is complete when:

1. ✅ `Redaction.swift` exists with complete implementation and documentation
2. ✅ `Snapshot.swift` uses centralized redaction (no hardcoded markers)
3. ✅ `RedactionTests.swift` exists with comprehensive test coverage
4. ✅ All verification commands pass (build, test, lint, sanitizer)
5. ✅ CI pipeline is green on all jobs
6. ✅ Documentation is complete and helpful
7. ✅ No breaking changes to existing public API
8. ✅ Code review ready (if applicable)

---

## 9. Dependencies and Assumptions

### 9.1 Dependencies
- **B1 (Binding.swift):** Completed - provides `isSecret` field on bindings
- **B3 (Snapshot.swift):** Completed - provides `ResolvedValue` and `displayValue`
- **B4 (DiagnosticsReport):** Assumed complete (or will integrate when available)

### 9.2 Assumptions
- The redaction marker `"[REDACTED]"` is appropriate and doesn't need i18n
- No requirement for partial redaction (e.g., showing last 4 characters)
- Binary secret flag is sufficient (no "sensitivity levels")
- No requirement for audit logging of redacted value access

### 9.3 Future Work (Out of Scope)
- Custom redaction markers per value
- Partial redaction strategies
- Runtime secret detection
- Integration with external secret managers
- Audit logging for secret access

---

## 10. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Breaking existing code during refactor | Medium | Run existing tests after each change; refactor is minimal |
| Missing edge cases in redaction logic | Low | Comprehensive test suite covers edge cases |
| Performance impact from function call overhead | Very Low | Inline-able static functions; negligible cost |
| Inconsistent usage across future code | Medium | Clear documentation and examples; code review |

---

## 11. References

- **Canonical PRD:** `DOCS/PRD/SpecificationConfig_PRD.md` §9 (Phase B, task B5)
- **PRD Authoring Rules:** `DOCS/RULES/01_PRD_PROMPT.md`
- **Current Binding Implementation:** `Sources/SpecificationConfig/Binding.swift`
- **Current Snapshot Implementation:** `Sources/SpecificationConfig/Snapshot.swift`
- **Existing Tests:** `Tests/SpecificationConfigTests/SnapshotTests.swift`
- **CI Configuration:** `.github/workflows/ci.yml`

---

## Appendix: Example Usage

### Before (Current State)
```swift
// Hardcoded in Snapshot.swift
public var displayValue: String {
    isSecret ? "[REDACTED]" : stringifiedValue
}
```

### After (With Redaction.swift)
```swift
// In application code
let apiKeyBinding = Binding(
    key: "stripe.secret_key",
    keyPath: \AppDraft.apiKey,
    decoder: { reader, key in try reader.get(key) },
    isSecret: true  // Automatically redacted everywhere
)

// In Snapshot.swift
public var displayValue: String {
    Redaction.redact(stringifiedValue, isSecret: isSecret)
}

// In future diagnostic code
let errorMessage = "Failed to validate \(Redaction.redact(value, isSecret: binding.isSecret))"
```

---

**End of PRD**
