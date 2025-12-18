# Task PRD: D1 — Add Minimal Helpers for Reading Primitives

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** D1
**Priority:** High
**Effort:** Medium
**Dependencies:** A2 (Swift Configuration)

---

## 1. Objective

Add minimal helper functions for reading primitive types (String, Bool, Int, URL) from `ConfigReader` to simplify binding decoder implementations and reduce boilerplate.

Currently, every decoder must manually wrap the key in `ConfigKey()` and call the appropriate method:
```swift
decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
```

With helpers, this becomes:
```swift
decoder: ConfigReader.string
```

**Source:** PRD §9 Phase D, Task D1

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Extension file `ConfigReader+Helpers.swift` with static helper functions
2. Helpers for primitive types: `String`, `Bool`, `Int`, `URL`
3. Simplified decoder syntax for common use cases
4. Comprehensive test coverage

### 2.2 What this task does NOT deliver

- Helpers for complex types (arrays, dictionaries, custom types)
- Automatic type conversions (that's a future enhancement)
- Default value handling (handled by Binding itself)
- Provenance extraction (that's D2)

### 2.3 Success Criteria

- [ ] `ConfigReader+Helpers.swift` extension file created
- [ ] Helper functions for String, Bool, Int, URL implemented
- [ ] Existing tests can be refactored to use helpers
- [ ] New tests verify helper behavior
- [ ] All existing tests continue to pass
- [ ] SwiftFormat compliance maintained

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: String helper**
- Static function matching decoder signature
- Wraps `reader.string(forKey: ConfigKey(key))`
- Returns `String?`

**Acceptance Criteria:**
- Function signature: `static func string(_ reader: ConfigReader, _ key: String) throws -> String?`
- Can be used directly as decoder: `decoder: ConfigReader.string`
- Behavior identical to manual implementation

**FR-2: Bool helper**
- Static function for reading boolean values
- Wraps `reader.bool(forKey: ConfigKey(key))`
- Returns `Bool?`

**Acceptance Criteria:**
- Function signature: `static func bool(_ reader: ConfigReader, _ key: String) throws -> Bool?`
- Can be used directly as decoder: `decoder: ConfigReader.bool`

**FR-3: Int helper**
- Static function for reading integer values
- Wraps `reader.int(forKey: ConfigKey(key))`
- Returns `Int?`

**Acceptance Criteria:**
- Function signature: `static func int(_ reader: ConfigReader, _ key: String) throws -> Int?`
- Can be used directly as decoder: `decoder: ConfigReader.int`

**FR-4: URL helper**
- Static function for reading URL values
- Wraps `reader.url(forKey: ConfigKey(key))`
- Returns `URL?`

**Acceptance Criteria:**
- Function signature: `static func url(_ reader: ConfigReader, _ key: String) throws -> URL?`
- Can be used directly as decoder: `decoder: ConfigReader.url`

### 3.2 Non-Functional Requirements

**NFR-1: Backward compatibility**
- Existing decoder implementations continue to work
- Helpers are additive, not breaking
- Migration to helpers is optional

**NFR-2: Ergonomics**
- Helper usage is more concise than manual implementation
- Type inference works correctly
- Error messages remain clear

**NFR-3: Performance**
- No performance overhead vs manual implementation
- Functions are inlined by compiler

---

## 4. Technical Design

### 4.1 Implementation Location

**New File:** `Sources/SpecificationConfig/ConfigReader+Helpers.swift`

### 4.2 Type Definitions

```swift
import Configuration
import Foundation

/// Convenience helpers for reading primitive configuration values.
///
/// These helpers simplify decoder implementations by eliminating boilerplate
/// for common primitive types. They can be used directly as decoder functions
/// in Binding definitions.
///
/// ## Example
///
/// ```swift
/// // Before (manual)
/// let nameBinding = Binding(
///     key: "app.name",
///     keyPath: \Draft.name,
///     decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
/// )
///
/// // After (with helper)
/// let nameBinding = Binding(
///     key: "app.name",
///     keyPath: \Draft.name,
///     decoder: ConfigReader.string
/// )
/// ```
extension ConfigReader {
    /// Reads a string value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The string value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    public static func string(_ reader: ConfigReader, _ key: String) throws -> String? {
        reader.string(forKey: ConfigKey(key))
    }

    /// Reads a boolean value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The boolean value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    public static func bool(_ reader: ConfigReader, _ key: String) throws -> Bool? {
        reader.bool(forKey: ConfigKey(key))
    }

    /// Reads an integer value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The integer value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    public static func int(_ reader: ConfigReader, _ key: String) throws -> Int? {
        reader.int(forKey: ConfigKey(key))
    }

    /// Reads a URL value from the configuration.
    ///
    /// - Parameters:
    ///   - reader: The configuration reader.
    ///   - key: The configuration key (without ConfigKey wrapper).
    /// - Returns: The URL value if present, nil otherwise.
    /// - Throws: Configuration errors if reading fails.
    public static func url(_ reader: ConfigReader, _ key: String) throws -> URL? {
        reader.url(forKey: ConfigKey(key))
    }
}
```

### 4.3 Key Design Decisions

**1. Extension vs separate type**
- Use extension on ConfigReader for discoverability
- Helpers appear as `ConfigReader.string` (natural for decoder usage)
- No new types to import or learn

**2. Static functions**
- Match decoder signature exactly: `(ConfigReader, String) throws -> Value?`
- Can be used as function references: `decoder: ConfigReader.string`
- Type inference works automatically

**3. Parameter labels**
- Use `_` for both parameters to match closure syntax
- Enables clean reference: `ConfigReader.string` (not `ConfigReader.string(_:_:)`)

**4. Limited scope**
- Only primitives that ConfigReader already supports
- No automatic conversions or complex types
- Keep it minimal and focused

---

## 5. Implementation Plan

### Phase 1: Core Implementation
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [ ] Create `Sources/SpecificationConfig/ConfigReader+Helpers.swift`
2. [ ] Add `string` helper function
3. [ ] Add `bool` helper function
4. [ ] Add `int` helper function
5. [ ] Add `url` helper function
6. [ ] Add doc comments for each helper
7. [ ] Add extension-level doc comment with example

**Verification:**
- Code compiles without errors
- Helpers are accessible as `ConfigReader.string`, etc.

### Phase 2: Test Coverage
**Estimated time:** 30-40 minutes

**Subtasks:**
1. [ ] Create `Tests/SpecificationConfigTests/ConfigReaderHelpersTests.swift`
2. [ ] Test `string` helper reads string values
3. [ ] Test `bool` helper reads boolean values
4. [ ] Test `int` helper reads integer values
5. [ ] Test `url` helper reads URL values
6. [ ] Test helpers return nil for missing keys
7. [ ] Test helpers work as decoder references in Binding
8. [ ] Optionally refactor one existing test to use helpers (demonstrate usage)

**Verification:**
- All new tests pass
- Existing tests continue to pass
- Test demonstrates helper can be used as decoder

### Phase 3: Verification
**Estimated time:** 5-10 minutes

**Subtasks:**
1. [ ] Run `swift build -v`
2. [ ] Run `swift test -v`
3. [ ] Run `swiftformat --lint .`
4. [ ] Verify test count increased appropriately

**Verification:**
- Build succeeds
- All tests pass (68+new tests)
- No SwiftFormat violations

---

## 6. Test Plan

### 6.1 New Test Cases

| Test Name | Purpose | Expected Outcome |
|-----------|---------|------------------|
| `testStringHelperReadsValue` | Verify string helper works | Returns expected string value |
| `testBoolHelperReadsValue` | Verify bool helper works | Returns expected boolean value |
| `testIntHelperReadsValue` | Verify int helper works | Returns expected integer value |
| `testURLHelperReadsValue` | Verify URL helper works | Returns expected URL value |
| `testHelpersReturnNilForMissingKey` | Verify nil for missing keys | All helpers return nil |
| `testHelperUsedAsDecoderInBinding` | Verify helper as decoder reference | Binding works with `ConfigReader.string` |

### 6.2 Edge Cases

| Edge Case | Expected Behavior | Test Coverage |
|-----------|-------------------|---------------|
| Missing key | Return nil | Covered in nil test |
| Empty string | Return empty string "" | Covered in basic test |
| Invalid URL string | ConfigReader handles error | Not helper's concern |
| Type mismatch | ConfigReader handles error | Not helper's concern |

### 6.3 Migration Example

Demonstrate refactoring an existing test:

**Before:**
```swift
let nameBinding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
)
```

**After:**
```swift
let nameBinding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: ConfigReader.string
)
```

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests
swift test -v

# 3. Run only new helper tests
swift test -v --filter ConfigReaderHelpersTests

# 4. Verify code formatting
swiftformat --lint .
```

**Success Criteria:**
- All commands exit with status 0
- Test count increases by ~6 tests
- No SwiftFormat violations
- No compilation warnings

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| A2 (Swift Configuration) | Required | ✅ Complete | ConfigReader API available |
| Configuration module | Required | ✅ Available | Imported in Package.swift |
| ConfigKey type | Required | ✅ Available | Part of Configuration |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Decoder signature mismatch | High | Low | Match exact signature from Binding |
| Type inference issues | Medium | Low | Test with actual Binding usage |
| ConfigReader methods don't exist | High | Very Low | Already used in tests |
| Breaking existing code | High | None | Helpers are additive only |

---

## 9. Definition of Done

This task is complete when:

- [ ] ⏳ `ConfigReader+Helpers.swift` extension file created
- [ ] ⏳ Four helper functions implemented (string, bool, int, url)
- [ ] ⏳ All helpers match decoder signature exactly
- [ ] ⏳ Helpers can be used as function references
- [ ] ⏳ ~6 new tests verify helper behavior
- [ ] ⏳ All existing tests pass (backward compatibility)
- [ ] ⏳ Documentation with usage examples
- [ ] ⏳ Verification commands succeed
- [ ] ⏳ SwiftFormat compliance maintained
- [ ] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Current State

**The implementation has NOT been started.** Current decoder implementations use manual wrapping:
```swift
decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
```

### 10.2 Usage Patterns

**Direct reference (preferred):**
```swift
let binding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: ConfigReader.string  // ← Direct reference
)
```

**Explicit closure (when customization needed):**
```swift
let binding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: { reader, key in
        // Custom logic before/after
        ConfigReader.string(reader, key)
    }
)
```

### 10.3 Future Enhancements

Potential extensions beyond D1 scope:
- Helpers for array types: `stringArray`, `intArray`
- Helpers for optional parsing: `stringOrDefault`
- Helpers with automatic conversion: `stringToInt`
- Composite helpers: `readAndValidate`

These are explicitly NOT in scope for D1.

---

## Appendix A: Before/After Comparison

### Current Code (Verbose)

```swift
let nameBinding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: { reader, key in reader.string(forKey: ConfigKey(key)) }
)

let portBinding = Binding(
    key: "app.port",
    keyPath: \Draft.port,
    decoder: { reader, key in reader.int(forKey: ConfigKey(key)) }
)

let enabledBinding = Binding(
    key: "app.enabled",
    keyPath: \Draft.enabled,
    decoder: { reader, key in reader.bool(forKey: ConfigKey(key)) }
)
```

### With Helpers (Concise)

```swift
let nameBinding = Binding(
    key: "app.name",
    keyPath: \Draft.name,
    decoder: ConfigReader.string
)

let portBinding = Binding(
    key: "app.port",
    keyPath: \Draft.port,
    decoder: ConfigReader.int
)

let enabledBinding = Binding(
    key: "app.enabled",
    keyPath: \Draft.enabled,
    decoder: ConfigReader.bool
)
```

**Reduction:** 70+ characters per binding eliminated, improved readability.

---

## Appendix B: Related Files

| File | Purpose | Changes |
|------|---------|---------|
| `Sources/SpecificationConfig/ConfigReader+Helpers.swift` | NEW - Helper functions | Create new file |
| `Tests/SpecificationConfigTests/ConfigReaderHelpersTests.swift` | NEW - Test coverage | Create new file |
| `Sources/SpecificationConfig/Binding.swift` | Binding definition | No changes needed |
| `Tests/SpecificationConfigTests/PipelineTests.swift` | Example refactor | Optional: demonstrate usage |

---

**End of PRD**
