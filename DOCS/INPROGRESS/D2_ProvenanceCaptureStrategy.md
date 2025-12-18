# Task PRD: D2 — Provenance Capture Strategy

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** D2
**Priority:** High
**Effort:** Medium
**Dependencies:** B3 (Snapshot), D1 (Helpers)

---

## 1. Objective

Implement provenance capture in ConfigPipeline to track the actual source of each configuration value in Snapshot, replacing the current placeholder implementation that uses `provenance: .unknown` and `stringifiedValue: "<applied>"`.

**Current State (Placeholder):**
```swift
let resolvedValue = ResolvedValue(
    key: binding.key,
    stringifiedValue: "<applied>",  // ← Placeholder
    provenance: .unknown,            // ← No source tracking
    isSecret: false                  // ← Not tracking from binding
)
```

**Target State (Actual Tracking):**
```swift
let resolvedValue = ResolvedValue(
    key: binding.key,
    stringifiedValue: actualValue,   // ← Actual value as string
    provenance: .fileProvider(name: "config.json"), // ← Real source
    isSecret: binding.isSecret       // ← From binding metadata
)
```

**Source:** PRD §9 Phase D, Task D2

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Strategy for capturing actual configuration values as strings
2. Implementation of provenance tracking from ConfigReader
3. Integration of `isSecret` flag from Binding into ResolvedValue
4. Updated Pipeline.swift to build proper Snapshot with real data
5. Comprehensive tests verifying provenance accuracy

### 2.2 What this task does NOT deliver

- Runtime value inspection via reflection (too complex, not needed)
- Provenance from Swift Configuration internals (if unavailable, use heuristics)
- UI for displaying snapshots (that's Phase E)
- Provenance modification after creation (immutable by design)

### 2.3 Success Criteria

- [ ] ConfigPipeline captures actual stringified values (not "<applied>")
- [ ] Provenance is determined from available context
- [ ] `isSecret` flag flows from Binding to ResolvedValue
- [ ] Tests verify correct provenance assignment
- [ ] Snapshot provides meaningful debugging information
- [ ] All existing tests continue to pass
- [ ] SwiftFormat compliance maintained

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Capture actual configuration values**
- Store actual value as string in ResolvedValue
- Use decoder's returned value, stringify it
- Handle nil values appropriately

**Acceptance Criteria:**
- String values stored as-is: `"MyApp"` → `"MyApp"`
- Int values stringified: `8080` → `"8080"`
- Bool values stringified: `true` → `"true"`
- Nil values represented: `nil` → `"<nil>"`

**FR-2: Track isSecret flag from Binding**
- Extract `isSecret` property from Binding
- Pass through to ResolvedValue
- Ensure redaction works in displayValue

**Acceptance Criteria:**
- Secret bindings create secret ResolvedValues
- Non-secret bindings create non-secret ResolvedValues
- displayValue respects isSecret flag

**FR-3: Determine provenance heuristically**
- Since Swift Configuration may not expose provenance, use heuristics
- Default value used → `Provenance.defaultValue`
- Decoder succeeded → `Provenance.unknown` (could be file/env, can't tell)
- Environment variable (if detectable) → `Provenance.environmentVariable`

**Acceptance Criteria:**
- Default values correctly marked as `.defaultValue`
- Successfully read values marked as `.unknown` (conservative)
- If env var detection available, mark as `.environmentVariable`

**FR-4: Handle value stringification**
- Convert decoder output to string representation
- Handle common types: String, Int, Bool, URL
- Fallback for other types

**Acceptance Criteria:**
- Common types stringify correctly
- Complex types use reasonable string representation
- Nil values handled gracefully

### 3.2 Non-Functional Requirements

**NFR-1: Performance**
- Minimal overhead vs current placeholder approach
- String conversion should be O(1) for primitives
- No expensive reflection or runtime inspection

**NFR-2: Debuggability**
- Snapshot provides useful information for troubleshooting
- Values are human-readable
- Provenance helps identify misconfiguration sources

**NFR-3: Type safety**
- No forced unwrapping or unsafe casts
- Generic approach works with all value types
- Compilation errors for unsupported operations

---

## 4. Technical Design

### 4.1 Implementation Approach

**Challenge:** The decoder runs inside Binding.apply() and we don't have access to the decoded value from outside. The binding writes directly to the draft via keyPath.

**Solution:** Modify Binding to optionally capture and return the decoded value for provenance tracking.

### 4.2 Enhanced Binding API

Add internal method to Binding for value capture:

```swift
extension Binding {
    // Internal method for pipeline to get value + metadata
    func applyAndCapture(
        to draft: inout Draft,
        reader: Configuration.ConfigReader
    ) throws -> (value: String?, usedDefault: Bool) {
        do {
            let decoded = try decoder(reader, key)
            draft[keyPath: keyPath] = decoded

            // Stringify the decoded value
            let stringified: String
            if let value = decoded {
                stringified = String(describing: value)
            } else {
                stringified = "<nil>"
            }

            return (stringified, false)

        } catch {
            // Try default value
            if let defaultValue = defaultValue {
                draft[keyPath: keyPath] = defaultValue
                return (String(describing: defaultValue), true)
            }
            throw error
        }
    }
}
```

### 4.3 Updated AnyBinding

Expose capture method through type erasure:

```swift
extension AnyBinding {
    func applyAndCapture(
        to draft: inout Draft,
        reader: Configuration.ConfigReader
    ) throws -> (value: String?, usedDefault: Bool) {
        // Delegate to underlying binding
        // Implementation requires storing closure in AnyBinding
    }
}
```

### 4.4 Updated Pipeline

Use new capture API:

```swift
for binding in profile.bindings {
    do {
        let (stringValue, usedDefault) = try binding.applyAndCapture(
            to: &draft,
            reader: reader
        )

        let provenance: Provenance = usedDefault ? .defaultValue : .unknown

        let resolvedValue = ResolvedValue(
            key: binding.key,
            stringifiedValue: stringValue ?? "<nil>",
            provenance: provenance,
            isSecret: binding.isSecret  // TODO: expose from AnyBinding
        )
        resolvedValues.append(resolvedValue)

    } catch {
        // Error handling...
    }
}
```

### 4.5 Alternative Simpler Approach

**If Binding modification is too complex,** use a simpler approach:

1. Keep current `apply()` method as-is
2. Add helper to stringify values after the fact (best-effort)
3. Accept `.unknown` provenance for now
4. Track `isSecret` separately (add to AnyBinding)

This delivers partial value but maintains simplicity.

### 4.6 Key Design Decisions

**1. Provenance granularity**
- Use `.unknown` conservatively when source unclear
- Only use `.defaultValue` when we know it was used
- Future: Could add `.fileProvider` detection if ConfigReader exposes it

**2. Value stringification**
- Use `String(describing:)` for general case
- Good enough for debugging
- Not meant for parsing or round-tripping

**3. isSecret tracking**
- Must flow from Binding → AnyBinding → Pipeline → ResolvedValue
- Add property to AnyBinding if not already present

**4. Incremental implementation**
- Phase 1: Track isSecret + basic stringification
- Phase 2: Enhance provenance detection if API allows
- Phase 3: (Future) Runtime provider introspection

---

## 5. Implementation Plan

### Phase 1: Add isSecret to AnyBinding
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [ ] Check if AnyBinding already exposes `isSecret`
2. [ ] If not, add `isSecret` property to AnyBinding
3. [ ] Store `isSecret` during AnyBinding initialization
4. [ ] Update Pipeline to use `binding.isSecret`

**Verification:**
- Code compiles
- isSecret flows through correctly

### Phase 2: Implement Value Capture
**Estimated time:** 40-60 minutes

**Subtasks:**
1. [ ] Decide on approach: modify Binding or simpler alternative
2. [ ] Implement chosen approach
3. [ ] Update Pipeline to capture stringified values
4. [ ] Track default value usage for provenance

**Verification:**
- Actual values appear in Snapshot (not "<applied>")
- Default values marked with `.defaultValue` provenance

### Phase 3: Test Coverage
**Estimated time:** 30-40 minutes

**Subtasks:**
1. [ ] Update existing tests to verify actual values in snapshot
2. [ ] Add test for isSecret flag propagation
3. [ ] Add test for default value provenance
4. [ ] Add test for nil value handling
5. [ ] Add test for different value types (String, Int, Bool)

**Verification:**
- All tests pass
- Snapshots contain meaningful data

### Phase 4: Verification
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [ ] Run `swift build -v`
2. [ ] Run `swift test -v`
3. [ ] Run `swiftformat --lint .`
4. [ ] Manually inspect snapshot contents in debugger

**Verification:**
- Build succeeds
- All tests pass
- SwiftFormat clean

---

## 6. Test Plan

### 6.1 New/Updated Test Cases

| Test Name | Purpose | Expected Outcome |
|-----------|---------|------------------|
| `testSnapshotContainsActualValues` | Verify real values captured | Snapshot has "TestApp" not "<applied>" |
| `testSnapshotTracksIsSecret` | Verify isSecret flows through | Secret binding → secret ResolvedValue |
| `testSnapshotProvenanceDefaultValue` | Verify default value provenance | Used default → `.defaultValue` |
| `testSnapshotProvenanceUnknown` | Verify read value provenance | Decoder succeeded → `.unknown` |
| `testSnapshotHandlesNilValues` | Verify nil handling | Nil value → "<nil>" string |
| `testSnapshotStringifiesDifferentTypes` | Verify type conversion | String, Int, Bool all stringify correctly |

### 6.2 Updated Existing Tests

| Test File | Changes Needed |
|-----------|----------------|
| `PipelineTests.swift` | Update assertions to check actual values vs "<applied>" |
| `SnapshotTests.swift` | May need updates if provenance assumptions changed |

### 6.3 Edge Cases

| Edge Case | Expected Behavior | Test Coverage |
|-----------|-------------------|---------------|
| Decoder returns nil | "<nil>" in stringifiedValue | New test |
| Default value used | `.defaultValue` provenance | New test |
| Secret + nil | isSecret=true, value="<nil>" | New test |
| Complex type | Best-effort String(describing:) | Nice to have |

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests
swift test -v

# 3. Run only updated tests
swift test -v --filter PipelineTests
swift test -v --filter SnapshotTests

# 4. Verify code formatting
swiftformat --lint .
```

**Success Criteria:**
- All commands exit with status 0
- Snapshot tests show actual values
- Provenance tests verify source tracking
- isSecret tests verify redaction

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| B3 (Snapshot) | Required | ✅ Complete | Provenance enum defined |
| D1 (Helpers) | Required | ✅ Complete | Helpers simplify decoder usage |
| Binding API | Required | ✅ Available | May need extension |
| AnyBinding | Required | ✅ Available | May need isSecret property |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Can't access decoded value | High | Medium | Use simpler approach: accept "<applied>" initially, enhance later |
| AnyBinding doesn't expose isSecret | Medium | Low | Add property to AnyBinding |
| Swift Configuration lacks provenance | Medium | High | Accept `.unknown`, document limitation |
| String conversion fails for types | Low | Low | Use String(describing:) fallback |

---

## 9. Definition of Done

This task is complete when:

- [ ] ⏳ Snapshot contains actual stringified values (not "<applied>")
- [ ] ⏳ isSecret flag flows from Binding to ResolvedValue
- [ ] ⏳ Default value usage tracked in provenance
- [ ] ⏳ Tests verify actual values in snapshots
- [ ] ⏳ Tests verify isSecret propagation
- [ ] ⏳ Tests verify provenance accuracy
- [ ] ⏳ All existing tests pass (backward compatibility)
- [ ] ⏳ Documentation updated if API changes
- [ ] ⏳ Verification commands succeed
- [ ] ⏳ SwiftFormat compliance maintained
- [ ] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Current State

**Pipeline.swift currently has placeholders (lines 145-156):**
```swift
// TODO: Track isSecret when AnyBinding exposes it
let resolvedValue = ResolvedValue(
    key: binding.key,
    stringifiedValue: "<applied>",
    provenance: .unknown,
    isSecret: false
)
```

**These TODOs must be resolved.**

### 10.2 Provenance Limitations

Swift Configuration may not expose detailed provenance. We'll use conservative approach:
- `.defaultValue` when we know default was used
- `.unknown` when decoder succeeded (could be file, env, etc.)
- Future enhancement: introspect ConfigReader if API allows

### 10.3 Value Stringification

For debugging purposes, we need human-readable strings:
- `String` → use as-is
- `Int`, `Bool`, `URL` → `String(describing:)`
- `nil` → `"<nil>"`
- Other types → `String(describing:)` (best effort)

### 10.4 isSecret Tracking

Need to check if AnyBinding already has `isSecret`. If not:
```swift
public struct AnyBinding<Draft> {
    public let key: String
    public let isSecret: Bool  // ← Add this

    // Store isSecret during init
    public init<Value>(_ binding: Binding<Draft, Value>) {
        self.key = binding.key
        self.isSecret = binding.isSecret
        // ... rest of init
    }
}
```

---

## Appendix A: Current vs Target Snapshot

### Current Snapshot (Placeholder)
```swift
Snapshot(
    resolvedValues: [
        ResolvedValue(
            key: "app.name",
            stringifiedValue: "<applied>",  // ← Not useful
            provenance: .unknown,            // ← No info
            isSecret: false                  // ← Wrong
        )
    ]
)
```

### Target Snapshot (Actual Data)
```swift
Snapshot(
    resolvedValues: [
        ResolvedValue(
            key: "app.name",
            stringifiedValue: "MyApp",               // ← Real value
            provenance: .unknown,                     // ← Conservative
            isSecret: false                           // ← Correct
        ),
        ResolvedValue(
            key: "api.key",
            stringifiedValue: "sk_prod_abc123",      // ← Real value
            provenance: .defaultValue,                // ← We know source
            isSecret: true                            // ← From binding
        )
    ]
)
```

---

## Appendix B: Related Files

| File | Purpose | Changes |
|------|---------|---------|
| `Sources/SpecificationConfig/Binding.swift` | Binding definition | Possible: add applyAndCapture method |
| `Sources/SpecificationConfig/AnyBinding.swift` | Type erasure | Add isSecret property if missing |
| `Sources/SpecificationConfig/Pipeline.swift` | Pipeline implementation | Replace placeholder with actual tracking (lines 145-156) |
| `Tests/SpecificationConfigTests/PipelineTests.swift` | Pipeline tests | Update to verify actual values |
| `Tests/SpecificationConfigTests/SnapshotTests.swift` | Snapshot tests | May need provenance assertion updates |

---

**End of PRD**
