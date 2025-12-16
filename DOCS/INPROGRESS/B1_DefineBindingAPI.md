# Task PRD: B1 — Define Binding<Draft, Value> Public API

**Task ID:** B1
**Phase:** B (Core types: Binding, AnyBinding, Snapshot, Diagnostics)
**Priority:** High
**Effort:** M (½–1d)
**Dependencies:** A2 (completed)
**Status:** Completed

---

## 1. Objective

Define the public API for `Binding<Draft, Value>`, the foundational generic type that maps a configuration key to a typed value and a `WritableKeyPath` in the Draft configuration object. This type encapsulates:
- Key-to-field mapping
- Value decoding logic
- Default values
- Value-level validation specs
- Secret/redaction flag

---

## 2. Scope

### In Scope
- Define `Binding<Draft, Value>` struct with full generic API
- Include properties for key, keyPath, decoder, default value, specs, and secret flag
- Define initializers for common use cases
- Add basic documentation comments
- Create minimal unit tests to verify API compiles

### Out of Scope
- Type erasure (`AnyBinding`) - covered in B2
- Actual pipeline execution logic - covered in C2
- Integration with ConfigReader - covered in D1
- Error handling types - covered in B4

---

## 3. Task Breakdown

### Subtask 3.1: Define Binding Structure
**Acceptance Criteria:**
- [ ] Create `Sources/SpecificationConfig/Binding.swift`
- [ ] Define `Binding<Draft, Value>` as a public struct with two generic parameters
- [ ] Mark as `Sendable` if appropriate for concurrency

### Subtask 3.2: Add Core Properties
**Acceptance Criteria:**
- [ ] `key: String` - The configuration key to read
- [ ] `keyPath: WritableKeyPath<Draft, Value?>` - Where to write the value in Draft
- [ ] `decoder: (Configuration.ConfigReader, String) throws -> Value?` - How to decode the value
- [ ] `defaultValue: Value?` - Default if key is missing
- [ ] `valueSpecs: [AnySpecification<Value>]` - Validation specs from SpecificationCore
- [ ] `isSecret: Bool` - Flag for redaction in diagnostics (default: false)

### Subtask 3.3: Add Initializers
**Acceptance Criteria:**
- [ ] Primary initializer accepting all parameters
- [ ] Convenience initializer with `isSecret` defaulting to `false`
- [ ] Convenience initializer with empty `valueSpecs` array as default
- [ ] All initializers are public

**Example API:**
```swift
public struct Binding<Draft, Value> {
    public let key: String
    public let keyPath: WritableKeyPath<Draft, Value?>
    public let decoder: (Configuration.ConfigReader, String) throws -> Value?
    public let defaultValue: Value?
    public let valueSpecs: [AnySpecification<Value>]
    public let isSecret: Bool

    public init(
        key: String,
        keyPath: WritableKeyPath<Draft, Value?>,
        decoder: @escaping (Configuration.ConfigReader, String) throws -> Value?,
        defaultValue: Value? = nil,
        valueSpecs: [AnySpecification<Value>] = [],
        isSecret: Bool = false
    )
}
```

### Subtask 3.4: Add Documentation Comments
**Acceptance Criteria:**
- [ ] Add DocC-style documentation to the struct
- [ ] Document each property's purpose
- [ ] Document initializer parameters
- [ ] Include usage example in documentation

### Subtask 3.5: Create Basic Unit Tests
**Acceptance Criteria:**
- [ ] Create `Tests/SpecificationConfigTests/BindingTests.swift`
- [ ] Test: Can create a Binding instance
- [ ] Test: Properties are correctly stored
- [ ] Test: Convenience initializers work with defaults
- [ ] Tests compile and pass

---

## 4. Implementation Design

### Type Signature
```swift
import Configuration
import SpecificationCore

/// A binding that maps a configuration key to a field in a Draft configuration object.
///
/// `Binding` encapsulates:
/// - The configuration key to read
/// - Where to write the decoded value (via KeyPath)
/// - How to decode the raw config value into a typed `Value`
/// - An optional default value
/// - Value-level validation specs from SpecificationCore
/// - Whether the value should be redacted in diagnostics (secrets)
///
/// Example:
/// ```swift
/// struct AppDraft {
///     var serverURL: URL?
///     var timeout: Int?
/// }
///
/// let binding = Binding(
///     key: "server.url",
///     keyPath: \AppDraft.serverURL,
///     decoder: { reader, key in try? URL(string: reader.get(key)) },
///     defaultValue: URL(string: "https://example.com")
/// )
/// ```
public struct Binding<Draft, Value> {
    // Properties...
    // Initializers...
}
```

### Key Design Decisions

1. **Generic Parameters:**
   - `Draft`: The intermediate config type with optional fields
   - `Value`: The type of the config value (e.g., String, Int, URL)

2. **KeyPath Type:**
   - Use `WritableKeyPath<Draft, Value?>` (optional Value)
   - Allows Draft to start with all nil fields
   - Pipeline can safely write values after validation

3. **Decoder Signature:**
   - `(Configuration.ConfigReader, String) throws -> Value?`
   - Returns optional (key might not exist)
   - Can throw for decode errors
   - Takes ConfigReader from swift-configuration

4. **Specs Type:**
   - Use `[AnySpecification<Value>]` from SpecificationCore
   - Type-erased specs allow heterogeneous collection
   - Empty array default for bindings without validation

5. **Secret Flag:**
   - `isSecret: Bool` with default `false`
   - Simple boolean for redaction in diagnostics
   - Will be used by Snapshot/Diagnostics in later tasks

---

## 5. Verification Commands

```bash
# Build should succeed
swift build

# Tests should compile and pass
swift test --filter BindingTests
```

**Expected Results:**
- Build succeeds
- At least 3 basic tests pass

---

## 6. Inputs

- PRD §3.1 (FR-1: Typed bindings with key-path mapping)
- PRD §5.2 (Binding implementation intent)
- `Configuration` module from swift-configuration (imported in A2)
- `SpecificationCore` module from SpecificationCore (imported in A2)

---

## 7. Outputs

- `Sources/SpecificationConfig/Binding.swift` (public API)
- `Tests/SpecificationConfigTests/BindingTests.swift` (basic tests)
- Foundation for B2 (AnyBinding type erasure)

---

## 8. Dependencies

**Depends on:**
- A2 (swift-configuration and SpecificationCore dependencies)

**Enables:**
- B2: AnyBinding type erasure
- B3: Snapshot model
- B4: Diagnostics types
- C1: SpecProfile

---

## 9. Edge Cases and Considerations

| Scenario | Approach |
|---|---|
| Value types that can't be sent across threads | Document that Value should be Sendable for concurrent use |
| Complex decoder logic | Decoder can be arbitrarily complex closure; user's responsibility |
| Specs with mismatched Value types | Type system prevents this at compile time |
| KeyPath to non-optional field | API requires `Value?` - enforced by type system |

---

## 10. Definition of Done

- [x] `Binding.swift` created with complete public API
- [x] All properties defined with appropriate types
- [x] At least one initializer with sensible defaults
- [x] DocC documentation on struct and key members
- [x] `BindingTests.swift` with 6 passing tests
- [x] `swift build` succeeds
- [x] `swift test` passes
- [x] Workplan marked B1 as `[x]`
- [x] This task PRD updated with completion status

## 11. Completion Notes

**Completed:** 2025-12-16

**Files Created:**
- `Sources/SpecificationConfig/Binding.swift` - Full generic API with documentation
- `Tests/SpecificationConfigTests/BindingTests.swift` - 6 passing unit tests

**Implementation Details:**
- Generic struct `Binding<Draft, Value>` with all required properties
- Full DocC-style documentation on all public members
- Platform requirements updated to macOS 15+ / iOS 18+ (required by swift-configuration)
- All tests pass (6 tests executed successfully)

**Test Coverage:**
- Binding initialization with all parameters
- Default parameter values
- Secret flag handling
- KeyPath type correctness
- Value specs array handling
- Decoder closure storage

---

## Notes

- This is the foundational type for the entire configuration pipeline
- Keep the API simple and composable
- Type erasure (AnyBinding) will come in B2 to allow heterogeneous collections
- The decoder closure design allows maximum flexibility for custom decoding logic
- SpecificationCore's `AnySpecification` already provides type erasure for specs
