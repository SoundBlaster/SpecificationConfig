# Task PRD: B4 — Define DiagnosticsReport & Error Items

**Task ID:** B4
**Task Name:** Define DiagnosticsReport & Error Items
**Priority:** High
**Effort:** M (½–1d)
**Dependencies:** B1 (completed)
**Phase:** B
**Status:** Completed

---

## 1. Scope and Intent

### 1.1 Objective

Create a formal diagnostics and error reporting system to collect, track, and display errors, warnings, and informational messages during configuration resolution. Provide a machine-readable error model with provenance tracking suitable for UI display and deterministic error reporting.

**Current state:**
- `Snapshot.swift` has placeholder `diagnostics: [String]` field
- No formal diagnostic types exist
- Error reporting is ad-hoc with string messages

**This task will:**
1. Create `Sources/SpecificationConfig/Diagnostics.swift` with formal diagnostic types
2. Define `DiagnosticItem` with severity levels, provenance, and context
3. Define `DiagnosticsReport` to collect and organize diagnostic items
4. Support deterministic ordering of diagnostics (by key, then stage)
5. Integrate with `Redaction` for secret values in error messages
6. Replace placeholder `diagnostics: [String]` in `Snapshot.swift`
7. Add comprehensive tests for all diagnostic scenarios

### 1.2 Primary Deliverables

| Deliverable | Type | Description | Success Criteria |
|---|---|---|---|
| `Diagnostics.swift` | Swift source file | Core diagnostic types and utilities | Compiles; public API documented |
| Updated `Snapshot.swift` | Swift source file | Uses `DiagnosticsReport` instead of `[String]` | Tests pass; type-safe diagnostics |
| Comprehensive tests | XCTest | Unit tests for diagnostic scenarios | CI green; covers all severity levels |
| Documentation | DocC comments | Clear diagnostic usage patterns | Examples for common error cases |

### 1.3 Success Criteria

- ✅ `Diagnostics.swift` exists in `Sources/SpecificationConfig/`
- ✅ `DiagnosticItem` supports error/warning/info severity levels
- ✅ `DiagnosticsReport` provides deterministic ordering
- ✅ `Snapshot.swift` uses proper diagnostic types
- ✅ All tests pass: `swift build -v && swift test -v`
- ✅ SwiftFormat passes: `swiftformat --lint .`
- ✅ Documentation clearly explains diagnostic creation and usage

### 1.4 Non-Goals

- No automatic error recovery or suggestions
- No localization or i18n support
- No network-based error reporting
- No breaking changes to existing `Snapshot` public API beyond replacing `diagnostics` type

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR-1: Diagnostic Severity Levels
**Description:** Support multiple severity levels for diagnostic messages.

**Acceptance Criteria:**
- Enum `DiagnosticSeverity` with cases: `.error`, `.warning`, `.info`
- Each diagnostic item has an associated severity
- Severity is Sendable and Equatable

#### FR-2: Diagnostic Context and Provenance
**Description:** Each diagnostic includes context about where and why it occurred.

**Acceptance Criteria:**
- Diagnostic includes configuration key (if applicable)
- Diagnostic includes message describing the issue
- Diagnostic includes optional context (e.g., expected type, actual value)
- Support for redaction of sensitive values in messages

#### FR-3: DiagnosticsReport Collection
**Description:** Collect multiple diagnostic items with deterministic ordering.

**Acceptance Criteria:**
- `DiagnosticsReport` holds array of `DiagnosticItem`
- Provides `hasErrors: Bool` computed property
- Provides `hasWarnings: Bool` computed property
- Items are ordered deterministically (by key alphabetically, then by severity)

#### FR-4: Integration with Snapshot
**Description:** Replace `diagnostics: [String]` with proper type-safe diagnostics.

**Acceptance Criteria:**
- `Snapshot.diagnostics` type changes from `[String]` to `DiagnosticsReport`
- `Snapshot.hasErrors` uses `diagnostics.hasErrors`
- Existing test expectations updated to use new types
- No breaking changes to other `Snapshot` properties

#### FR-5: Redaction Support in Diagnostics
**Description:** Secret values mentioned in diagnostics must be redacted.

**Acceptance Criteria:**
- Diagnostic messages can reference values safely
- Integration with `Redaction.redact()` for secret values
- Examples show how to create diagnostics with potential secrets

### 2.2 Non-Functional Requirements

#### NFR-1: Performance
- Diagnostic collection must be O(n) where n is number of diagnostics
- Sorting/ordering overhead should be minimal
- No unnecessary allocations

#### NFR-2: Type Safety
- Use Swift type system to prevent misuse
- Sendable conformance for concurrency safety
- Clear, compile-time API

#### NFR-3: Testability
- All diagnostic logic is unit-testable
- Deterministic ordering is verifiable
- Mock-friendly design

#### NFR-4: Usability
- Clear, actionable error messages
- Consistent formatting across diagnostic types
- Easy to create diagnostics in calling code

---

## 3. Technical Design

### 3.1 File Structure

```
Sources/SpecificationConfig/
  Diagnostics.swift       ← NEW (this task)
  Snapshot.swift          ← UPDATE (replace diagnostics field)
  Redaction.swift         ← No changes (already exists)
  Binding.swift           ← No changes
  AnyBinding.swift        ← No changes
  SpecificationConfig.swift ← No changes

Tests/SpecificationConfigTests/
  DiagnosticsTests.swift  ← NEW (comprehensive tests)
  SnapshotTests.swift     ← UPDATE (adapt to new diagnostics type)
```

### 3.2 API Design: Diagnostics.swift

```swift
import Foundation

/// Severity level for diagnostic messages.
///
/// Diagnostics can be errors (build failures), warnings (potential issues),
/// or informational messages (debug/audit trail).
public enum DiagnosticSeverity: String, Sendable, Equatable, Comparable {
    /// Critical error that prevents configuration build
    case error

    /// Warning about potential issues (non-blocking)
    case warning

    /// Informational message for debugging/audit
    case info

    public static func < (lhs: DiagnosticSeverity, rhs: DiagnosticSeverity) -> Bool {
        let order: [DiagnosticSeverity] = [.error, .warning, .info]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

/// A single diagnostic message with context.
///
/// Represents an error, warning, or informational message encountered
/// during configuration resolution. Includes the configuration key,
/// severity, and descriptive message.
///
/// ## Example
///
/// ```swift
/// let diagnostic = DiagnosticItem(
///     key: "api.timeout",
///     severity: .error,
///     message: "Invalid timeout value: expected positive integer, got '-5'"
/// )
/// ```
public struct DiagnosticItem: Sendable, Equatable {
    /// The configuration key this diagnostic relates to (if applicable)
    public let key: String?

    /// The severity level of this diagnostic
    public let severity: DiagnosticSeverity

    /// Human-readable description of the issue
    public let message: String

    /// Creates a diagnostic item.
    ///
    /// - Parameters:
    ///   - key: The configuration key (optional)
    ///   - severity: The severity level
    ///   - message: Description of the issue
    public init(
        key: String? = nil,
        severity: DiagnosticSeverity,
        message: String
    ) {
        self.key = key
        self.severity = severity
        self.message = message
    }
}

/// Collection of diagnostic messages from configuration resolution.
///
/// Collects errors, warnings, and informational messages in a deterministic
/// order. Provides convenience methods to check for errors or warnings.
///
/// ## Example
///
/// ```swift
/// var report = DiagnosticsReport()
/// report.add(key: "db.host", severity: .error, message: "Missing required field")
/// report.add(key: "app.name", severity: .warning, message: "Using default value")
///
/// if report.hasErrors {
///     print("Configuration build failed with \(report.errorCount) errors")
/// }
/// ```
public struct DiagnosticsReport: Sendable, Equatable {
    /// All diagnostic items, stored in insertion order
    private var items: [DiagnosticItem]

    /// All diagnostic items in deterministic order.
    ///
    /// Items are sorted by:
    /// 1. Key (alphabetically, with nil keys last)
    /// 2. Severity (errors before warnings before info)
    /// 3. Message (alphabetically, for stable ordering)
    public var diagnostics: [DiagnosticItem] {
        items.sorted { lhs, rhs in
            // Sort by key first (nil keys go last)
            switch (lhs.key, rhs.key) {
            case (nil, nil):
                break // Continue to severity comparison
            case (nil, _):
                return false // nil keys go last
            case (_, nil):
                return true // non-nil keys go first
            case let (lhsKey?, rhsKey?):
                if lhsKey != rhsKey {
                    return lhsKey < rhsKey
                }
            }

            // Sort by severity
            if lhs.severity != rhs.severity {
                return lhs.severity < rhs.severity
            }

            // Sort by message for stable ordering
            return lhs.message < rhs.message
        }
    }

    /// Whether this report contains any errors
    public var hasErrors: Bool {
        items.contains { $0.severity == .error }
    }

    /// Whether this report contains any warnings
    public var hasWarnings: Bool {
        items.contains { $0.severity == .warning }
    }

    /// Number of error diagnostics
    public var errorCount: Int {
        items.filter { $0.severity == .error }.count
    }

    /// Number of warning diagnostics
    public var warningCount: Int {
        items.filter { $0.severity == .warning }.count
    }

    /// Number of info diagnostics
    public var infoCount: Int {
        items.filter { $0.severity == .info }.count
    }

    /// Total number of diagnostics
    public var count: Int {
        items.count
    }

    /// Whether this report is empty
    public var isEmpty: Bool {
        items.isEmpty
    }

    /// Creates an empty diagnostics report.
    public init() {
        self.items = []
    }

    /// Creates a diagnostics report with initial items.
    ///
    /// - Parameter items: Initial diagnostic items
    public init(items: [DiagnosticItem]) {
        self.items = items
    }

    /// Adds a diagnostic item to the report.
    ///
    /// - Parameter item: The diagnostic item to add
    public mutating func add(_ item: DiagnosticItem) {
        items.append(item)
    }

    /// Adds a diagnostic with individual components.
    ///
    /// - Parameters:
    ///   - key: The configuration key (optional)
    ///   - severity: The severity level
    ///   - message: Description of the issue
    public mutating func add(
        key: String? = nil,
        severity: DiagnosticSeverity,
        message: String
    ) {
        let item = DiagnosticItem(key: key, severity: severity, message: message)
        add(item)
    }

    /// Merges another diagnostics report into this one.
    ///
    /// - Parameter other: The report to merge
    public mutating func merge(_ other: DiagnosticsReport) {
        items.append(contentsOf: other.items)
    }
}
```

### 3.3 Changes to Snapshot.swift

Update the `Snapshot` struct to use `DiagnosticsReport`:

```swift
// Before (line ~129):
/// Placeholder for diagnostics messages.
///
/// This will be replaced with proper `DiagnosticItem` types in B4.
/// For now, stores string messages for errors/warnings.
public let diagnostics: [String]

/// Whether this snapshot contains any errors.
///
/// Currently checks if diagnostics array is non-empty.
/// Will be enhanced in B4 when proper diagnostic types are added.
public var hasErrors: Bool {
    !diagnostics.isEmpty
}

// After:
/// Diagnostic messages collected during configuration resolution.
///
/// Contains errors, warnings, and informational messages with context
/// about what went wrong and where.
public let diagnostics: DiagnosticsReport

/// Whether this snapshot contains any errors.
///
/// Returns true if any diagnostic has severity `.error`.
public var hasErrors: Bool {
    diagnostics.hasErrors
}
```

Update the initializer:

```swift
// Before (line ~145):
public init(
    resolvedValues: [ResolvedValue] = [],
    timestamp: Date = Date(),
    diagnostics: [String] = []
)

// After:
public init(
    resolvedValues: [ResolvedValue] = [],
    timestamp: Date = Date(),
    diagnostics: DiagnosticsReport = DiagnosticsReport()
)
```

---

## 4. Implementation Plan

### 4.1 Task Breakdown (Hierarchical TODO)

#### Phase 1: Create Diagnostics.swift (High Priority, 2-3h)
- [ ] **Task 1.1:** Create file `Sources/SpecificationConfig/Diagnostics.swift`
  - **Input:** API design from §3.2
  - **Output:** Compiling Swift file with public API
  - **Verification:** `swift build -v` succeeds
  - **Acceptance:** File exists and compiles without errors

- [ ] **Task 1.2:** Implement `DiagnosticSeverity` enum
  - **Input:** Design specification
  - **Output:** Sendable, Equatable, Comparable enum
  - **Verification:** Can compare severities: `.error < .warning`
  - **Acceptance:** Enum is properly ordered and documented

- [ ] **Task 1.3:** Implement `DiagnosticItem` struct
  - **Input:** Struct design from §3.2
  - **Output:** Sendable, Equatable struct with all properties
  - **Verification:** Can create items with different severities
  - **Acceptance:** Struct compiles and is well-documented

- [ ] **Task 1.4:** Implement `DiagnosticsReport` struct (basic)
  - **Input:** Struct design from §3.2
  - **Output:** Basic structure with storage and init
  - **Verification:** Can create empty report
  - **Acceptance:** Basic structure compiles

- [ ] **Task 1.5:** Implement deterministic sorting in `diagnostics` property
  - **Input:** Sorting requirements (key, severity, message)
  - **Output:** Computed property with stable sorting
  - **Verification:** Items are sorted correctly
  - **Acceptance:** Sorting is deterministic and testable

- [ ] **Task 1.6:** Implement convenience properties (hasErrors, counts, etc.)
  - **Input:** API design
  - **Output:** All computed properties
  - **Verification:** Properties return correct values
  - **Acceptance:** All convenience methods work correctly

- [ ] **Task 1.7:** Implement add() and merge() methods
  - **Input:** Method signatures from §3.2
  - **Output:** Mutating methods for adding diagnostics
  - **Verification:** Can add and merge diagnostics
  - **Acceptance:** Methods work correctly and maintain order

- [ ] **Task 1.8:** Add comprehensive DocC documentation
  - **Input:** API design with usage examples
  - **Output:** Fully documented public API
  - **Verification:** Documentation builds without warnings
  - **Acceptance:** All public members have clear documentation

#### Phase 2: Update Snapshot.swift (High Priority, 30min-1h)
- [ ] **Task 2.1:** Update diagnostics field type
  - **Input:** Current Snapshot.swift (line ~129)
  - **Output:** Changed `diagnostics: [String]` to `diagnostics: DiagnosticsReport`
  - **Verification:** Code compiles
  - **Acceptance:** Type is updated, docstring updated

- [ ] **Task 2.2:** Update hasErrors computed property
  - **Input:** Current implementation (line ~135)
  - **Output:** Uses `diagnostics.hasErrors`
  - **Verification:** Logic is correct
  - **Acceptance:** Property uses new diagnostic API

- [ ] **Task 2.3:** Update Snapshot initializer
  - **Input:** Current initializer (line ~145)
  - **Output:** Default parameter is `DiagnosticsReport()` instead of `[]`
  - **Verification:** Can create snapshots with and without diagnostics
  - **Acceptance:** Initializer works with new type

#### Phase 3: Update Existing Tests (High Priority, 1h)
- [ ] **Task 3.1:** Update SnapshotTests.swift for new diagnostics type
  - **Input:** Existing SnapshotTests.swift
  - **Output:** Tests adapted to DiagnosticsReport
  - **Verification:** All snapshot tests pass
  - **Acceptance:** No test failures from type change

- [ ] **Task 3.2:** Update test expectations for hasErrors
  - **Input:** Existing hasErrors tests
  - **Output:** Tests use DiagnosticsReport API
  - **Verification:** Tests verify error detection correctly
  - **Acceptance:** Tests cover new diagnostic capabilities

#### Phase 4: Add Comprehensive Diagnostic Tests (High Priority, 2-3h)
- [ ] **Task 4.1:** Create `Tests/SpecificationConfigTests/DiagnosticsTests.swift`
  - **Input:** Test plan from §5
  - **Output:** New test file with test structure
  - **Verification:** File compiles and is discovered by test runner
  - **Acceptance:** Test file exists and imports necessary modules

- [ ] **Task 4.2:** Test DiagnosticSeverity ordering
  - **Input:** Severity enum
  - **Output:** Tests verifying `.error < .warning < .info`
  - **Verification:** `swift test -v` passes
  - **Acceptance:** All severity comparisons work correctly

- [ ] **Task 4.3:** Test DiagnosticItem creation and properties
  - **Input:** DiagnosticItem API
  - **Output:** Tests for all init variants
  - **Verification:** Items created correctly
  - **Acceptance:** Tests cover all properties

- [ ] **Task 4.4:** Test DiagnosticsReport basic operations
  - **Input:** DiagnosticsReport API
  - **Output:** Tests for add(), merge(), isEmpty, count
  - **Verification:** All operations work correctly
  - **Verification:** All test cases pass
  - **Acceptance:** Basic operations are thoroughly tested

- [ ] **Task 4.5:** Test deterministic ordering
  - **Input:** Sorting requirements
  - **Output:** Tests verifying stable sort order
  - **Verification:** Same input always produces same output
  - **Acceptance:** Golden tests prove determinism

- [ ] **Task 4.6:** Test hasErrors, hasWarnings, counts
  - **Input:** Convenience properties
  - **Output:** Tests for all computed properties
  - **Verification:** Properties return correct values
  - **Acceptance:** All edge cases covered

- [ ] **Task 4.7:** Test multiple diagnostics with mixed severities
  - **Input:** Complex scenarios
  - **Output:** Tests with errors + warnings + info mixed
  - **Verification:** Correct ordering and filtering
  - **Acceptance:** Real-world scenarios work correctly

#### Phase 5: Quality Assurance (High Priority, 30min)
- [ ] **Task 5.1:** Run full test suite
  - **Input:** All implemented code and tests
  - **Output:** Passing CI locally
  - **Verification:** `swift build -v && swift test -v` succeeds
  - **Acceptance:** Zero test failures, zero build errors

- [ ] **Task 5.2:** Run SwiftFormat lint
  - **Input:** All modified files
  - **Output:** Formatted code
  - **Verification:** `swiftformat --lint .` passes
  - **Acceptance:** No formatting issues reported

- [ ] **Task 5.3:** Run Thread Sanitizer
  - **Input:** Test suite
  - **Output:** Clean sanitizer run
  - **Verification:** `swift test --sanitize=thread` passes
  - **Acceptance:** No threading issues detected (Sendable conformance verified)

- [ ] **Task 5.4:** Verify documentation completeness
  - **Input:** All public API in Diagnostics.swift
  - **Output:** Confirmation of complete documentation
  - **Verification:** Manual review of DocC comments
  - **Acceptance:** All public types, properties, and functions documented

---

## 5. Test Plan

### 5.1 Unit Tests (DiagnosticsTests.swift)

#### Test Suite 1: DiagnosticSeverity
```swift
func testSeverityOrdering() {
    XCTAssertLessThan(DiagnosticSeverity.error, .warning)
    XCTAssertLessThan(DiagnosticSeverity.warning, .info)
    XCTAssertLessThan(DiagnosticSeverity.error, .info)
}

func testSeverityEquality() {
    XCTAssertEqual(DiagnosticSeverity.error, .error)
    XCTAssertNotEqual(DiagnosticSeverity.error, .warning)
}
```

#### Test Suite 2: DiagnosticItem
```swift
func testDiagnosticItemCreation() {
    let item = DiagnosticItem(
        key: "test.key",
        severity: .error,
        message: "Test message"
    )
    XCTAssertEqual(item.key, "test.key")
    XCTAssertEqual(item.severity, .error)
    XCTAssertEqual(item.message, "Test message")
}

func testDiagnosticItemWithoutKey() {
    let item = DiagnosticItem(
        severity: .warning,
        message: "General warning"
    )
    XCTAssertNil(item.key)
    XCTAssertEqual(item.severity, .warning)
}

func testDiagnosticItemEquality() {
    let item1 = DiagnosticItem(key: "a", severity: .error, message: "msg")
    let item2 = DiagnosticItem(key: "a", severity: .error, message: "msg")
    let item3 = DiagnosticItem(key: "b", severity: .error, message: "msg")

    XCTAssertEqual(item1, item2)
    XCTAssertNotEqual(item1, item3)
}
```

#### Test Suite 3: DiagnosticsReport Basic Operations
```swift
func testEmptyReport() {
    let report = DiagnosticsReport()
    XCTAssertTrue(report.isEmpty)
    XCTAssertEqual(report.count, 0)
    XCTAssertFalse(report.hasErrors)
    XCTAssertFalse(report.hasWarnings)
}

func testAddSingleDiagnostic() {
    var report = DiagnosticsReport()
    report.add(key: "test", severity: .error, message: "Error")

    XCTAssertFalse(report.isEmpty)
    XCTAssertEqual(report.count, 1)
    XCTAssertTrue(report.hasErrors)
}

func testAddMultipleDiagnostics() {
    var report = DiagnosticsReport()
    report.add(key: "a", severity: .error, message: "Error 1")
    report.add(key: "b", severity: .warning, message: "Warning 1")
    report.add(key: "c", severity: .info, message: "Info 1")

    XCTAssertEqual(report.count, 3)
    XCTAssertEqual(report.errorCount, 1)
    XCTAssertEqual(report.warningCount, 1)
    XCTAssertEqual(report.infoCount, 1)
}

func testMergeReports() {
    var report1 = DiagnosticsReport()
    report1.add(key: "a", severity: .error, message: "Error")

    var report2 = DiagnosticsReport()
    report2.add(key: "b", severity: .warning, message: "Warning")

    report1.merge(report2)

    XCTAssertEqual(report1.count, 2)
    XCTAssertTrue(report1.hasErrors)
    XCTAssertTrue(report1.hasWarnings)
}
```

#### Test Suite 4: Deterministic Ordering
```swift
func testDiagnosticsOrderedByKey() {
    var report = DiagnosticsReport()
    report.add(key: "c", severity: .error, message: "Third")
    report.add(key: "a", severity: .error, message: "First")
    report.add(key: "b", severity: .error, message: "Second")

    let ordered = report.diagnostics
    XCTAssertEqual(ordered[0].key, "a")
    XCTAssertEqual(ordered[1].key, "b")
    XCTAssertEqual(ordered[2].key, "c")
}

func testDiagnosticsOrderedBySeverity() {
    var report = DiagnosticsReport()
    report.add(key: "a", severity: .info, message: "Info")
    report.add(key: "a", severity: .error, message: "Error")
    report.add(key: "a", severity: .warning, message: "Warning")

    let ordered = report.diagnostics
    XCTAssertEqual(ordered[0].severity, .error)
    XCTAssertEqual(ordered[1].severity, .warning)
    XCTAssertEqual(ordered[2].severity, .info)
}

func testDiagnosticsOrderedByMessage() {
    var report = DiagnosticsReport()
    report.add(key: "a", severity: .error, message: "Z message")
    report.add(key: "a", severity: .error, message: "A message")
    report.add(key: "a", severity: .error, message: "M message")

    let ordered = report.diagnostics
    XCTAssertEqual(ordered[0].message, "A message")
    XCTAssertEqual(ordered[1].message, "M message")
    XCTAssertEqual(ordered[2].message, "Z message")
}

func testDiagnosticsNilKeysLast() {
    var report = DiagnosticsReport()
    report.add(key: nil, severity: .error, message: "No key")
    report.add(key: "a", severity: .error, message: "Has key")

    let ordered = report.diagnostics
    XCTAssertEqual(ordered[0].key, "a")
    XCTAssertNil(ordered[1].key)
}

func testDeterministicOrderingRepeated() {
    // Verify same input produces same output every time
    func createReport() -> DiagnosticsReport {
        var report = DiagnosticsReport()
        report.add(key: "z", severity: .warning, message: "Last")
        report.add(key: "a", severity: .error, message: "First error")
        report.add(key: nil, severity: .info, message: "No key")
        report.add(key: "a", severity: .warning, message: "First warning")
        report.add(key: "m", severity: .error, message: "Middle")
        return report
    }

    let report1 = createReport()
    let report2 = createReport()

    XCTAssertEqual(report1.diagnostics, report2.diagnostics)
}
```

#### Test Suite 5: Convenience Properties
```swift
func testHasErrors() {
    var report = DiagnosticsReport()
    XCTAssertFalse(report.hasErrors)

    report.add(key: "a", severity: .warning, message: "Warning")
    XCTAssertFalse(report.hasErrors)

    report.add(key: "b", severity: .error, message: "Error")
    XCTAssertTrue(report.hasErrors)
}

func testHasWarnings() {
    var report = DiagnosticsReport()
    XCTAssertFalse(report.hasWarnings)

    report.add(key: "a", severity: .info, message: "Info")
    XCTAssertFalse(report.hasWarnings)

    report.add(key: "b", severity: .warning, message: "Warning")
    XCTAssertTrue(report.hasWarnings)
}

func testCounts() {
    var report = DiagnosticsReport()
    report.add(key: "a", severity: .error, message: "Error 1")
    report.add(key: "b", severity: .error, message: "Error 2")
    report.add(key: "c", severity: .warning, message: "Warning")
    report.add(key: "d", severity: .info, message: "Info")

    XCTAssertEqual(report.errorCount, 2)
    XCTAssertEqual(report.warningCount, 1)
    XCTAssertEqual(report.infoCount, 1)
    XCTAssertEqual(report.count, 4)
}
```

### 5.2 Integration Tests (SnapshotTests.swift updates)

```swift
func testSnapshotWithDiagnostics() {
    var diagnostics = DiagnosticsReport()
    diagnostics.add(key: "test.key", severity: .error, message: "Test error")

    let snapshot = Snapshot(
        resolvedValues: [],
        diagnostics: diagnostics
    )

    XCTAssertTrue(snapshot.hasErrors)
    XCTAssertEqual(snapshot.diagnostics.count, 1)
}

func testSnapshotWithoutDiagnostics() {
    let snapshot = Snapshot()

    XCTAssertFalse(snapshot.hasErrors)
    XCTAssertTrue(snapshot.diagnostics.isEmpty)
}

func testSnapshotErrorDetection() {
    var errorReport = DiagnosticsReport()
    errorReport.add(severity: .error, message: "Critical error")

    var warningReport = DiagnosticsReport()
    warningReport.add(severity: .warning, message: "Just a warning")

    let errorSnapshot = Snapshot(diagnostics: errorReport)
    let warningSnapshot = Snapshot(diagnostics: warningReport)

    XCTAssertTrue(errorSnapshot.hasErrors)
    XCTAssertFalse(warningSnapshot.hasErrors)
}
```

---

## 6. Acceptance Criteria

### 6.1 Code Quality
- [ ] All code follows Swift API design guidelines
- [ ] SwiftFormat passes with zero warnings
- [ ] No compiler warnings
- [ ] No force-unwraps or unsafe constructs
- [ ] All types are Sendable for concurrency safety

### 6.2 Testing
- [ ] Unit test coverage for all public API
- [ ] Deterministic ordering is verified with golden tests
- [ ] Thread Sanitizer passes
- [ ] All tests are deterministic and repeatable
- [ ] Edge cases are tested and documented

### 6.3 Documentation
- [ ] All public types have DocC comments
- [ ] Examples are provided for common use cases
- [ ] Diagnostic creation patterns are documented
- [ ] Comments explain "why" not just "what"

### 6.4 Integration
- [ ] Existing snapshot tests continue to pass
- [ ] No breaking changes to Snapshot public API (beyond diagnostics field type)
- [ ] Type change is backward-compatible at call sites
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

# 5. Build in release mode
swift build -c release
```

**Success criteria:** All commands complete without errors or warnings.

---

## 8. Definition of Done

This task is complete when:

1. ✅ `Diagnostics.swift` exists with complete implementation and documentation
2. ✅ `Snapshot.swift` uses `DiagnosticsReport` instead of `[String]`
3. ✅ `DiagnosticsTests.swift` exists with comprehensive test coverage
4. ✅ `SnapshotTests.swift` updated and all tests pass
5. ✅ All verification commands pass (build, test, lint, sanitizer)
6. ✅ CI pipeline is green on all jobs
7. ✅ Documentation is complete and helpful
8. ✅ Deterministic ordering is verified
9. ✅ Code review ready (if applicable)

---

## 9. Dependencies and Assumptions

### 9.1 Dependencies
- **B1 (Binding.swift):** Completed - provides binding infrastructure
- **B3 (Snapshot.swift):** Completed - provides snapshot model to update
- **B5 (Redaction.swift):** Completed - provides redaction utilities (may be referenced in diagnostics)

### 9.2 Assumptions
- Diagnostic messages are in English (no localization required)
- Deterministic ordering is key → severity → message
- No requirement for diagnostic codes or error IDs
- No requirement for structured metadata beyond key/severity/message
- Snapshot API can have minor breaking change (diagnostics field type)

### 9.3 Future Work (Out of Scope)
- Diagnostic error codes or structured identifiers
- Localization/i18n of messages
- Diagnostic suggestions or fix-its
- Integration with logging frameworks
- Performance metrics for diagnostics collection

---

## 10. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Breaking change to Snapshot API | Medium | Carefully update all call sites; type checker catches issues |
| Ordering algorithm performance | Low | Simple sort with clear complexity; test with large datasets |
| Missing edge cases in sorting | Medium | Comprehensive test suite with nil keys, same keys, etc. |
| Integration with future pipeline code | Low | Clean API with clear separation of concerns |

---

## 11. References

- **Canonical PRD:** `DOCS/PRD/SpecificationConfig_PRD.md` §1 (diagnostics model), §9 (Phase B, task B4)
- **PRD Authoring Rules:** `DOCS/RULES/01_PRD_PROMPT.md`
- **Current Snapshot Implementation:** `Sources/SpecificationConfig/Snapshot.swift`
- **Redaction Utilities:** `Sources/SpecificationConfig/Redaction.swift`
- **Existing Tests:** `Tests/SpecificationConfigTests/SnapshotTests.swift`
- **CI Configuration:** `.github/workflows/ci.yml`

---

## Appendix: Example Usage

### Creating Diagnostics

```swift
// In configuration resolution code
var diagnostics = DiagnosticsReport()

// Add error for missing required field
diagnostics.add(
    key: "database.host",
    severity: .error,
    message: "Required field is missing"
)

// Add warning for default value usage
diagnostics.add(
    key: "app.timeout",
    severity: .warning,
    message: "Using default timeout of 30s"
)

// Add info for successful resolution
diagnostics.add(
    key: "app.name",
    severity: .info,
    message: "Resolved from environment variable APP_NAME"
)
```

### Using in Snapshot

```swift
// Create snapshot with diagnostics
let snapshot = Snapshot(
    resolvedValues: values,
    diagnostics: diagnostics
)

// Check for errors
if snapshot.hasErrors {
    print("Configuration build failed with \(snapshot.diagnostics.errorCount) errors:")
    for diagnostic in snapshot.diagnostics.diagnostics where diagnostic.severity == .error {
        print("  [\(diagnostic.key ?? "general")] \(diagnostic.message)")
    }
}
```

### Deterministic Output

```swift
// No matter what order diagnostics are added, output is consistent
var report1 = DiagnosticsReport()
report1.add(key: "z", severity: .error, message: "Last")
report1.add(key: "a", severity: .error, message: "First")

var report2 = DiagnosticsReport()
report2.add(key: "a", severity: .error, message: "First")
report2.add(key: "z", severity: .error, message: "Last")

// Both produce same ordered output: ["a", "z"]
assert(report1.diagnostics == report2.diagnostics)
```

---

**End of PRD**
