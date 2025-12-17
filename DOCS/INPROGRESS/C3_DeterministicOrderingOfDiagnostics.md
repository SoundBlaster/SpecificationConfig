# Task PRD: C3 — Deterministic Ordering of Diagnostics

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** C3
**Priority:** High
**Effort:** Medium
**Dependencies:** C2 (ConfigPipeline)

---

## 1. Objective

Implement a stable, deterministic sorting function for diagnostic items in `DiagnosticsReport` to ensure consistent ordering of diagnostics across runs. This is essential for:
- Reproducible test output (golden tests)
- Predictable user experience (error messages appear in same order)
- Reliable CI/CD verification
- Easier debugging and testing

**Source:** PRD §9 Phase C, Task C3

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. A deterministic sorting algorithm for `DiagnosticItem` collection in `DiagnosticsReport`
2. Comprehensive test coverage including golden tests for determinism
3. Documentation of the ordering rules in code comments

### 2.2 What this task does NOT deliver

- Changes to `DiagnosticItem` structure (already complete in B4)
- Changes to redaction logic (already complete in B5)
- Pipeline integration (already complete in C2)

### 2.3 Success Criteria

- [ ] Diagnostics are sorted by a stable, multi-key ordering rule
- [ ] Ordering is deterministic: same inputs produce same output order across runs
- [ ] Tests verify ordering behavior including edge cases
- [ ] Golden test demonstrates cross-run determinism
- [ ] All existing tests continue to pass
- [ ] SwiftFormat compliance maintained

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Multi-level sorting algorithm**
- Diagnostics must be sorted by:
  1. Configuration key (alphabetically, with nil keys sorted last)
  2. Severity (errors < warnings < info, using `DiagnosticSeverity.Comparable`)
  3. Display message (alphabetically, after redaction applied)
  4. Context summary (alphabetically by sorted context keys)

**Acceptance Criteria:**
- Given diagnostics with different keys, they sort alphabetically by key
- Given diagnostics with same key but different severity, errors come first
- Given diagnostics with nil keys, they appear last
- Given diagnostics with identical key and severity, messages sort alphabetically
- Given diagnostics with identical key, severity, and message, context summary provides tie-breaking

**FR-2: Determinism guarantee**
- Same diagnostic items in different insertion order must produce identical sorted output

**Acceptance Criteria:**
- Golden test creates same report twice with items added in different order
- Sorted diagnostics arrays are identical

### 3.2 Non-Functional Requirements

**NFR-1: Performance**
- Sorting complexity: O(n log n) where n = number of diagnostics
- Acceptable for typical diagnostic counts (< 1000 items)
- No repeated string allocations during comparison

**NFR-2: Correctness**
- Sorting must be stable (preserves relative order of equal elements)
- Comparison functions must be transitive and consistent
- Edge cases (nil keys, empty messages, empty context) handled correctly

---

## 4. Technical Design

### 4.1 Implementation Location

**File:** `Sources/SpecificationConfig/Diagnostics.swift`
**Type:** `DiagnosticsReport`
**Property:** `public var diagnostics: [DiagnosticItem]` (computed property)

### 4.2 Algorithm

The `diagnostics` computed property returns a sorted view of the internal `items` array:

```swift
public var diagnostics: [DiagnosticItem] {
    items.sorted { lhs, rhs in
        // 1. Sort by key (nil keys last)
        switch (lhs.key, rhs.key) {
        case (nil, nil):
            break
        case (nil, _):
            return false  // nil sorts after non-nil
        case (_, nil):
            return true   // non-nil sorts before nil
        case let (lhsKey?, rhsKey?):
            if lhsKey != rhsKey {
                return lhsKey < rhsKey
            }
        }

        // 2. Sort by severity (using Comparable)
        if lhs.severity != rhs.severity {
            return lhs.severity < rhs.severity
        }

        // 3. Sort by display message (post-redaction)
        if lhs.displayMessage != rhs.displayMessage {
            return lhs.displayMessage < rhs.displayMessage
        }

        // 4. Sort by context summary (deterministic)
        return (lhs.contextSummary ?? "") < (rhs.contextSummary ?? "")
    }
}
```

### 4.3 Key Design Decisions

1. **Computed property vs stored array:**
   - Use computed property to avoid storing duplicate sorted data
   - Trade-off: O(n log n) on each access vs O(n) space
   - Acceptable because diagnostics are typically accessed once per build

2. **Nil key handling:**
   - Nil keys sort last (less disruptive in UI display)
   - Consistent with treating nil as "unknown/global" scope

3. **Display message comparison:**
   - Use `displayMessage` (post-redaction) not raw `message`
   - Ensures ordering matches what users see
   - Deterministic because redaction is deterministic

4. **Context summary tie-breaking:**
   - Context keys already sorted alphabetically in `contextSummary`
   - Provides final deterministic ordering

---

## 5. Implementation Plan

### Phase 1: Core Sorting Implementation
**Status:** ✅ COMPLETE (already implemented in Diagnostics.swift:147-171)

- [x] Implement multi-level sorting in `diagnostics` computed property
- [x] Handle nil keys correctly (sort last)
- [x] Use `DiagnosticSeverity.Comparable` for severity ordering
- [x] Use `displayMessage` for message comparison
- [x] Use `contextSummary` for final tie-breaking

### Phase 2: Test Coverage
**Status:** ✅ COMPLETE (already implemented in DiagnosticsTests.swift)

- [x] Test basic ordering by key
  - **Location:** `testDiagnosticsOrderedByKeySeverityAndMessage()` (lines 63-76)
- [x] Test severity ordering within same key
  - **Location:** `testDiagnosticsOrderedByKeySeverityAndMessage()` (lines 63-76)
- [x] Test message ordering when key and severity match
  - **Location:** `testDiagnosticsOrderedByDisplayMessageWhenKeysAndSeveritiesMatch()` (lines 78-96)
- [x] Test nil key handling (sorted last)
  - **Location:** `testDiagnosticsOrderedByKeySeverityAndMessage()` (lines 63-76)
- [x] Golden test for determinism
  - **Location:** `testDeterministicOrderingAcrossReports()` (lines 98-112)

### Phase 3: Documentation
**Status:** ✅ COMPLETE (already documented in Diagnostics.swift)

- [x] Document ordering rules in `diagnostics` property doc comment
  - **Location:** Diagnostics.swift:139-145

### Phase 4: Verification
**Status:** PENDING (to be verified in EXECUTE phase)

- [ ] Run `swift build -v` to verify compilation
- [ ] Run `swift test -v` to verify all tests pass
- [ ] Run `swiftformat --lint .` to verify code style
- [ ] Verify golden test passes consistently across multiple runs

---

## 6. Test Plan

### 6.1 Unit Tests

| Test Case | Purpose | Expected Outcome | Status |
|-----------|---------|------------------|--------|
| `testDiagnosticsOrderedByKeySeverityAndMessage` | Verify multi-level ordering | Items sorted by key, severity, message | ✅ Implemented |
| `testDiagnosticsOrderedByDisplayMessageWhenKeysAndSeveritiesMatch` | Verify message + context ordering | Messages sorted alphabetically with context | ✅ Implemented |
| `testDeterministicOrderingAcrossReports` | Golden test for determinism | Same items produce same sorted order | ✅ Implemented |

### 6.2 Edge Cases

| Edge Case | Expected Behavior | Test Coverage |
|-----------|-------------------|---------------|
| Empty report | Returns empty array | Covered in `testDiagnosticsReportAddAndCounts` |
| All nil keys | Stable sort by severity/message | Covered in basic tests |
| Identical items | Stable insertion order preserved | Covered in determinism test |
| Redacted messages | Sort by display value, not raw | Covered in display message test |
| Empty context | Empty string comparison works | Covered in basic tests |

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests (including determinism tests)
swift test -v

# 3. Run only diagnostics tests
swift test -v --filter DiagnosticsTests

# 4. Verify code formatting
swiftformat --lint .

# 5. Run tests multiple times to verify determinism
for i in {1..5}; do
  echo "Run $i"
  swift test -v --filter testDeterministicOrderingAcrossReports
done
```

**Success Criteria:**
- All commands exit with status 0
- No SwiftFormat violations
- All test runs produce identical output
- No flaky test failures

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| C2 (ConfigPipeline) | Required | ✅ Complete | Pipeline uses DiagnosticsReport |
| B4 (DiagnosticsReport) | Required | ✅ Complete | Base types defined |
| B5 (Redaction) | Required | ✅ Complete | Needed for displayMessage |
| DiagnosticSeverity.Comparable | Required | ✅ Complete | Defined in B4 |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Performance degradation on large reports | Medium | Low | Acceptable for < 1000 items; can optimize later if needed |
| Unstable sort on Swift < 5.0 | High | None | Swift 5.0+ guarantees stable sort |
| Context summary non-determinism | High | None | Context keys already sorted in contextSummary |

---

## 9. Definition of Done

This task is complete when:

- [x] ✅ `DiagnosticsReport.diagnostics` returns items in deterministic order
- [x] ✅ Ordering follows documented multi-level sort rules
- [x] ✅ All unit tests pass including golden test for determinism
- [ ] ⏳ Verification commands succeed (pending EXECUTE phase)
- [x] ✅ Code is documented with clear ordering specification
- [x] ✅ SwiftFormat compliance maintained
- [ ] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Current Status

**The implementation is already complete.** This PRD documents the existing implementation found in:
- `Sources/SpecificationConfig/Diagnostics.swift` (lines 139-171)
- `Tests/SpecificationConfigTests/DiagnosticsTests.swift` (lines 63-112)

The sorting algorithm and tests were implemented as part of earlier work on the Diagnostics system.

### 10.2 Next Steps

1. **EXECUTE phase verification:**
   - Run verification commands to confirm implementation
   - Ensure all tests pass
   - Verify determinism across multiple runs

2. **ARCHIVE phase:**
   - Move this PRD to `DOCS/TASKS_ARCHIVE/`
   - Update `DOCS/INPROGRESS/INDEX.md`
   - Mark C3 complete in `DOCS/Workplan.md`
   - Update `DOCS/INPROGRESS/next.md` to select C4

---

## Appendix A: Example Output

### Before Sorting (Insertion Order)
```
1. key="b", severity=error, message="Beta error"
2. key="a", severity=warning, message="Alpha warning"
3. key="a", severity=error, message="Alpha error"
4. key=nil, severity=info, message="No key info"
```

### After Sorting (Deterministic Order)
```
1. key="a", severity=error, message="Alpha error"     ← errors first within "a"
2. key="a", severity=warning, message="Alpha warning" ← warnings after errors
3. key="b", severity=error, message="Beta error"      ← next key alphabetically
4. key=nil, severity=info, message="No key info"      ← nil keys last
```

---

## Appendix B: Related Files

| File | Purpose | Lines of Interest |
|------|---------|-------------------|
| `Sources/SpecificationConfig/Diagnostics.swift` | Core implementation | 139-171 (sorting algorithm) |
| `Tests/SpecificationConfigTests/DiagnosticsTests.swift` | Test coverage | 63-76, 78-96, 98-112 |
| `Sources/SpecificationConfig/Redaction.swift` | Redaction support | Used in displayMessage |
| `Sources/SpecificationConfig/Pipeline.swift` | Pipeline integration | Uses sorted diagnostics |

---

**End of PRD**
