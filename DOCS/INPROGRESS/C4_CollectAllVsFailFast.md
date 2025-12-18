# Task PRD: C4 — Add Collect-All vs Fail-Fast Option

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** C4
**Priority:** Medium
**Effort:** Medium
**Dependencies:** C2 (ConfigPipeline)

---

## 1. Objective

Add a configurable error handling mode to `ConfigPipeline.build()` that allows choosing between:
- **Collect-all mode** (default): Continue processing all bindings and collect all errors before failing
- **Fail-fast mode**: Stop at the first binding error and return immediately

This provides flexibility for different use cases:
- Collect-all is better for user-facing config validation (show all errors at once)
- Fail-fast is useful for development/debugging (fail quickly on first issue)

**Source:** PRD §9 Phase C, Task C4

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. An `ErrorHandlingMode` enum with two cases: `collectAll` and `failFast`
2. A parameter in `ConfigPipeline.build()` to specify the mode (default: `collectAll`)
3. Modified binding application logic to support both modes
4. Comprehensive test coverage for both modes

### 2.2 What this task does NOT deliver

- Changes to error types or diagnostic structure (already complete)
- Changes to finalization error handling (already works for both modes)
- UI or logging integration (application layer concern)

### 2.3 Success Criteria

- [ ] `ErrorHandlingMode` enum defined with two cases
- [ ] `build()` method accepts optional `errorHandlingMode` parameter
- [ ] Default mode is `collectAll`
- [ ] Collect-all mode continues through all bindings even when errors occur
- [ ] Fail-fast mode stops at first binding error
- [ ] All existing tests continue to pass
- [ ] New tests verify both modes work correctly
- [ ] SwiftFormat compliance maintained

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Error handling mode enumeration**
- Define `ErrorHandlingMode` enum with two cases
- Cases: `.collectAll`, `.failFast`
- Make it public and sendable for use in concurrent contexts

**Acceptance Criteria:**
- Enum is defined in Pipeline.swift
- Both cases are documented
- Enum conforms to Sendable

**FR-2: Collect-all mode (default)**
- When a binding fails, collect the error diagnostic
- Continue processing remaining bindings
- Return failure only after all bindings have been attempted
- Report all collected errors in the diagnostics

**Acceptance Criteria:**
- Multiple binding errors are collected
- All bindings are attempted even if some fail
- Final diagnostics contain all errors
- Snapshot contains values from successful bindings

**FR-3: Fail-fast mode (opt-in)**
- When a binding fails, immediately return failure
- Do not process remaining bindings
- Return the first error encountered

**Acceptance Criteria:**
- Pipeline stops at first error
- Only one error in diagnostics
- Remaining bindings are not processed
- Snapshot contains values from bindings before the failure

**FR-4: API design**
- Add `errorHandlingMode` parameter to `build()` method
- Default value: `.collectAll`
- Parameter placement: after `reader` parameter

**Acceptance Criteria:**
- Existing callers work without changes (default behavior)
- New parameter can be specified explicitly
- API is clear and self-documenting

### 3.2 Non-Functional Requirements

**NFR-1: Backward compatibility**
- Existing code calling `build(profile:reader:)` continues to work
- Default behavior is collect-all (better for users)
- No breaking changes to public API

**NFR-2: Performance**
- Collect-all mode: O(N) where N = number of bindings
- Fail-fast mode: O(1) to O(N) depending on where error occurs
- No memory overhead beyond collecting diagnostics

**NFR-3: Clarity**
- Mode names are self-explanatory
- Documentation explains when to use each mode
- Tests clearly demonstrate both behaviors

---

## 4. Technical Design

### 4.1 Implementation Location

**File:** `Sources/SpecificationConfig/Pipeline.swift`

**Changes:**
1. Add `ErrorHandlingMode` enum (before `ConfigPipeline` enum)
2. Modify `build()` signature to accept `errorHandlingMode` parameter
3. Update binding application loop to handle both modes

### 4.2 Type Definitions

```swift
/// Error handling strategy for configuration pipeline.
///
/// Determines whether the pipeline stops at the first error or collects
/// all errors before failing.
public enum ErrorHandlingMode: Sendable {
    /// Collect all binding errors before failing.
    ///
    /// The pipeline will attempt to apply all bindings even if some fail,
    /// collecting diagnostic messages for all failures. This is the default
    /// mode and is recommended for user-facing configuration validation
    /// where showing all errors at once provides better user experience.
    case collectAll

    /// Stop at the first binding error.
    ///
    /// The pipeline will return immediately upon encountering the first
    /// binding failure. Useful for development and debugging where you
    /// want to fail quickly and fix issues one at a time.
    case failFast
}
```

### 4.3 Modified Build Signature

```swift
public static func build<Draft, Final>(
    profile: SpecProfile<Draft, Final>,
    reader: Configuration.ConfigReader,
    errorHandlingMode: ErrorHandlingMode = .collectAll
) -> BuildResult<Final>
```

### 4.4 Algorithm Changes

**Current behavior (fail-fast only):**
```swift
for binding in profile.bindings {
    do {
        try binding.apply(to: &draft, reader: reader)
        // Track resolved value
    } catch {
        // Add diagnostic
        return .failure(...)  // ← Immediate return
    }
}
```

**New behavior (mode-aware):**
```swift
for binding in profile.bindings {
    do {
        try binding.apply(to: &draft, reader: reader)
        // Track resolved value
    } catch let error as ConfigError {
        let diagnostic = diagnosticFromConfigError(error, key: binding.key)
        diagnostics.add(diagnostic)

        // Mode-specific behavior
        switch errorHandlingMode {
        case .failFast:
            let snapshot = Snapshot(
                resolvedValues: resolvedValues,
                diagnostics: DiagnosticsReport()
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot)
        case .collectAll:
            continue  // Keep processing remaining bindings
        }

    } catch {
        diagnostics.add(
            key: binding.key,
            severity: .error,
            message: "Binding application failed: \(error.localizedDescription)"
        )

        // Mode-specific behavior
        switch errorHandlingMode {
        case .failFast:
            let snapshot = Snapshot(
                resolvedValues: resolvedValues,
                diagnostics: DiagnosticsReport()
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot)
        case .collectAll:
            continue  // Keep processing remaining bindings
        }
    }
}

// Check if we collected any errors (in collect-all mode)
if diagnostics.hasErrors {
    let snapshot = Snapshot(
        resolvedValues: resolvedValues,
        diagnostics: DiagnosticsReport()
    )
    return .failure(diagnostics: diagnostics, snapshot: snapshot)
}
```

### 4.5 Key Design Decisions

**1. Default mode: collectAll**
- Rationale: Better user experience (see all errors at once)
- Trade-off: Slightly more processing time if multiple errors
- Justification: User-facing config validation benefits from complete error reports

**2. Parameter placement**
- After `reader` parameter, before return type
- Default value provided for backward compatibility
- Clear parameter name (no abbreviations)

**3. Mode handling location**
- In catch blocks (not after loop)
- Allows immediate return for fail-fast
- Keeps error handling logic localized

**4. Finalization behavior**
- Both modes behave the same during finalization
- If finalization fails, return immediately (regardless of mode)
- Rationale: Finalization error means complete failure, no point continuing

---

## 5. Implementation Plan

### Phase 1: Core Implementation
**Estimated time:** 30-45 minutes

**Subtasks:**
1. [ ] Add `ErrorHandlingMode` enum to Pipeline.swift
   - Define enum with two cases
   - Add doc comments explaining when to use each
   - Conform to Sendable

2. [ ] Update `build()` signature
   - Add `errorHandlingMode` parameter with default value
   - Update doc comment to explain the parameter

3. [ ] Modify binding application loop
   - Add switch statement in catch blocks
   - Handle `.failFast` with immediate return (existing behavior)
   - Handle `.collectAll` with continue statement
   - Ensure `if diagnostics.hasErrors` check remains (lines 162-169)

**Verification:**
- Code compiles without errors
- Existing tests still pass (verifying backward compatibility)

### Phase 2: Test Coverage
**Estimated time:** 30-45 minutes

**Subtasks:**
1. [ ] Add test for collect-all mode with multiple errors
   - Create 3 bindings: 1st succeeds, 2nd fails, 3rd fails
   - Verify all bindings are attempted
   - Verify diagnostics contains 2 errors
   - Verify snapshot contains 1 resolved value (from 1st binding)

2. [ ] Add test for fail-fast mode
   - Create 3 bindings: 1st succeeds, 2nd fails, 3rd would fail
   - Use `.failFast` mode
   - Verify only first error is reported
   - Verify 3rd binding was not attempted (via side effect tracking)

3. [ ] Add test for default behavior
   - Call build() without specifying mode
   - Verify collect-all behavior (default)

4. [ ] Add test for all bindings failing in collect-all mode
   - Create 3 bindings that all fail
   - Verify all 3 errors are collected
   - Verify snapshot is empty (no successful bindings)

**Verification:**
- All new tests pass
- Test names clearly describe what they verify
- Code coverage includes both branches of switch statements

### Phase 3: Documentation
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [ ] Update `ConfigPipeline` doc comment
   - Mention error handling modes
   - Explain default behavior

2. [ ] Update `build()` method doc comment
   - Document `errorHandlingMode` parameter
   - Provide usage examples for both modes

**Verification:**
- Doc comments are clear and accurate
- Examples compile (if provided as code snippets)

### Phase 4: Verification
**Estimated time:** 5-10 minutes

**Subtasks:**
1. [ ] Run `swift build -v`
2. [ ] Run `swift test -v`
3. [ ] Run `swiftformat --lint .`
4. [ ] Verify all existing tests still pass

**Verification:**
- Build succeeds
- All 72+ tests pass (68 existing + 4+ new)
- No SwiftFormat violations

---

## 6. Test Plan

### 6.1 New Test Cases

| Test Name | Purpose | Expected Outcome |
|-----------|---------|------------------|
| `testCollectAllModeWithMultipleErrors` | Verify collect-all collects multiple binding errors | All bindings attempted, all errors collected |
| `testFailFastModeStopsAtFirstError` | Verify fail-fast stops immediately | Only first error reported, remaining bindings not attempted |
| `testDefaultModeIsCollectAll` | Verify default behavior | Calling without mode parameter uses collect-all |
| `testCollectAllModeWithAllBindingsFailing` | Verify collect-all with complete failure | All errors collected, empty snapshot |

### 6.2 Existing Tests to Verify

All existing PipelineTests should continue to pass:
- `testPipelineSuccessWithAllBindings`
- `testPipelineSuccessWithDefaultValues`
- `testPipelineFailureOnBindingSpecViolation`
- `testPipelineFailureOnMissingRequiredValue`
- `testPipelineFailureOnFinalizationError`
- `testPipelineFailureOnFinalSpecViolation`
- `testBindingsAppliedInDeclaredOrder`
- `testSnapshotContainsResolvedValues`
- `testBuildResultDiagnosticsAccessor`
- `testBuildResultSnapshotAccessor`

### 6.3 Edge Cases

| Edge Case | Expected Behavior | Test Coverage |
|-----------|-------------------|---------------|
| Single binding fails in fail-fast | Immediate failure | Covered by `testFailFastModeStopsAtFirstError` |
| Last binding fails in collect-all | All bindings attempted, error reported | Covered by `testCollectAllModeWithMultipleErrors` |
| No bindings fail | Success regardless of mode | Covered by existing tests |
| Finalization fails after collect-all | Failure with finalization error + binding errors | Will be covered if needed |

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests
swift test -v

# 3. Run only pipeline tests
swift test -v --filter PipelineTests

# 4. Verify code formatting
swiftformat --lint .

# 5. Run specific new tests
swift test -v --filter testCollectAllModeWithMultipleErrors
swift test -v --filter testFailFastModeStopsAtFirstError
swift test -v --filter testDefaultModeIsCollectAll
```

**Success Criteria:**
- All commands exit with status 0
- Total test count increases by 4
- No SwiftFormat violations
- No test failures or flaky tests

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| C2 (ConfigPipeline) | Required | ✅ Complete | Base implementation exists |
| B4 (DiagnosticsReport) | Required | ✅ Complete | Error collection works |
| Existing PipelineTests | Required | ✅ Complete | Must continue passing |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Breaking existing API callers | High | Low | Use default parameter value for backward compatibility |
| Collect-all mode causing confusion | Medium | Low | Clear documentation + sensible default |
| Performance regression | Medium | Very Low | Both modes are O(N), minimal overhead |
| Test complexity | Low | Medium | Keep tests simple and focused on one aspect each |

---

## 9. Definition of Done

This task is complete when:

- [x] ⏳ `ErrorHandlingMode` enum defined with `.collectAll` and `.failFast`
- [x] ⏳ `build()` method accepts `errorHandlingMode` parameter (default: `.collectAll`)
- [x] ⏳ Collect-all mode collects all binding errors before failing
- [x] ⏳ Fail-fast mode stops at first binding error
- [x] ⏳ All existing tests pass (backward compatibility verified)
- [x] ⏳ 4+ new tests verify both modes work correctly
- [x] ⏳ Documentation updated for new parameter
- [x] ⏳ Verification commands succeed
- [x] ⏳ SwiftFormat compliance maintained
- [ ] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Current State

**The implementation is NOT yet started.** The current Pipeline.swift behavior is fail-fast only (returns immediately on first error at lines 138-159).

### 10.2 Migration Path

**For existing code:**
- No changes required - default mode is collect-all
- Existing tests may need updates if they expect fail-fast behavior
- Check existing tests to ensure they work with collect-all default

**For new code:**
- Use default (collect-all) for user-facing validation
- Explicitly specify `.failFast` for development/debugging scenarios

### 10.3 Example Usage

```swift
// Default behavior (collect-all)
let result = ConfigPipeline.build(profile: myProfile, reader: configReader)
// Will collect all binding errors

// Explicit fail-fast
let result = ConfigPipeline.build(
    profile: myProfile,
    reader: configReader,
    errorHandlingMode: .failFast
)
// Will stop at first error

// Process result
switch result {
case let .success(config, snapshot):
    print("Config built successfully")
case let .failure(diagnostics, snapshot):
    print("Build failed with \(diagnostics.errorCount) errors")
    for diagnostic in diagnostics.diagnostics where diagnostic.severity == .error {
        print("  - \(diagnostic.displayMessage)")
    }
}
```

---

## Appendix A: Behavior Comparison

### Scenario: 3 bindings, binding 2 and 3 fail

**Fail-Fast Mode:**
1. Binding 1: ✅ Success → track value
2. Binding 2: ❌ Error → add diagnostic, return immediately
3. Binding 3: (not attempted)

Result: 1 error in diagnostics, 1 value in snapshot

**Collect-All Mode:**
1. Binding 1: ✅ Success → track value
2. Binding 2: ❌ Error → add diagnostic, continue
3. Binding 3: ❌ Error → add diagnostic, continue
4. Check diagnostics → has errors → return failure

Result: 2 errors in diagnostics, 1 value in snapshot

---

## Appendix B: Related Files

| File | Purpose | Lines of Interest |
|------|---------|-------------------|
| `Sources/SpecificationConfig/Pipeline.swift` | Core implementation | 105-205 (build method) |
| `Tests/SpecificationConfigTests/PipelineTests.swift` | Test coverage | All tests, + 4 new tests |
| `Sources/SpecificationConfig/Diagnostics.swift` | Error collection | Used for collecting errors |

---

**End of PRD**
