# Task PRD: B2 — Implement AnyBinding<Draft> Type Erasure

**Task ID:** B2
**Phase:** B (Core types: Binding, AnyBinding, Snapshot, Diagnostics)
**Priority:** High
**Effort:** L (1–3d)
**Dependencies:** B1 (completed)
**Status:** Complete

---

## 1. Objective

Implement `AnyBinding<Draft>` as a type-erased wrapper around `Binding<Draft, Value>` to enable storing bindings with different `Value` types in a single homogeneous collection. This is essential for the configuration pipeline to process multiple bindings of heterogeneous types.

---

## 2. Scope

### In Scope
- Define `AnyBinding<Draft>` struct with type erasure
- Implement initializer that accepts `Binding<Draft, Value>`
- Preserve key access
- Implement `apply(to:reader:)` method for executing binding logic
- Add comprehensive unit tests
- Ensure B1's Binding.swift exists (dependency)

### Out of Scope
- Actual error types (covered in B4)
- Provenance/Snapshot types (covered in B3)
- Pipeline orchestration (covered in C2)
- ConfigReader helpers (covered in D1)

---

## 3. Task Breakdown

### Subtask 3.1: Verify B1 Dependency
**Acceptance Criteria:**
- [ ] Ensure `Binding.swift` exists (from B1)
- [ ] If not present, cherry-pick or create minimal Binding for development

### Subtask 3.2: Define AnyBinding Structure
**Acceptance Criteria:**
- [ ] Create `Sources/SpecificationConfig/AnyBinding.swift`
- [ ] Define `AnyBinding<Draft>` as a public struct
- [ ] Store type-erased closures for binding operations

### Subtask 3.3: Implement Type Erasure Pattern
**Acceptance Criteria:**
- [ ] Store `key: String` property
- [ ] Store `_apply: (inout Draft, ConfigReader) throws -> Void` closure
- [ ] Implement init accepting `Binding<Draft, Value>`
- [ ] Erase Value type in initialization

**Type Erasure Design:**
```swift
public struct AnyBinding<Draft> {
    public let key: String

    private let _apply: (inout Draft, Configuration.ConfigReader) throws -> Void

    public init<Value>(_ binding: Binding<Draft, Value>) {
        self.key = binding.key
        self._apply = { draft, reader in
            // 1. Decode value using binding's decoder
            // 2. Apply default if needed
            // 3. Run value specs (validation)
            // 4. Write to draft via keyPath if valid
            // Note: Error handling will be simplified for now (B4 adds proper errors)
        }
    }

    public func apply(to draft: inout Draft, reader: Configuration.ConfigReader) throws {
        try _apply(&draft, reader)
    }
}
```

### Subtask 3.4: Implement Apply Logic
**Acceptance Criteria:**
- [ ] In `_apply` closure: call binding's decoder
- [ ] Handle missing keys (use default value if provided)
- [ ] Run value specs on decoded value
- [ ] Write validated value to draft via keyPath
- [ ] For now, throw simple errors (proper error types come in B4)

**Apply Logic Flow:**
1. Try to decode value using `binding.decoder(reader, key)`
2. If decode returns nil and default exists, use default
3. If value exists, run all `valueSpecs`
4. If all specs pass, write to `draft[keyPath: binding.keyPath]`
5. If spec fails or decode throws, propagate error

### Subtask 3.5: Add Documentation
**Acceptance Criteria:**
- [ ] DocC documentation on `AnyBinding` struct
- [ ] Document init and apply methods
- [ ] Include usage example showing heterogeneous array

### Subtask 3.6: Create Comprehensive Unit Tests
**Acceptance Criteria:**
- [ ] Create `Tests/SpecificationConfigTests/AnyBindingTests.swift`
- [ ] Test: Can create AnyBinding from Binding
- [ ] Test: Key is preserved through type erasure
- [ ] Test: Apply successfully writes to draft
- [ ] Test: Apply handles missing keys with defaults
- [ ] Test: Apply throws on decode errors
- [ ] Test: Can store multiple AnyBindings with different Value types in array
- [ ] At least 6 passing tests

---

## 4. Implementation Design

### Full API Sketch

```swift
import Configuration
import SpecificationCore

/// A type-erased binding that can store `Binding<Draft, Value>` instances with
/// different `Value` types in a homogeneous collection.
///
/// `AnyBinding` wraps a `Binding` and erases its `Value` type parameter, allowing
/// you to create arrays like `[AnyBinding<AppDraft>]` containing bindings for
/// String, Int, Bool, URL, etc.
///
/// Example:
/// ```swift
/// struct AppDraft {
///     var name: String?
///     var port: Int?
///     var enabled: Bool?
/// }
///
/// let nameBinding = Binding<AppDraft, String>(
///     key: "app.name",
///     keyPath: \AppDraft.name,
///     decoder: { reader, key in try? reader.get(key) }
/// )
///
/// let portBinding = Binding<AppDraft, Int>(
///     key: "app.port",
///     keyPath: \AppDraft.port,
///     decoder: { reader, key in try? reader.get(key) }
/// )
///
/// // Store heterogeneous bindings in a single array
/// let bindings: [AnyBinding<AppDraft>] = [
///     AnyBinding(nameBinding),
///     AnyBinding(portBinding)
/// ]
///
/// // Apply all bindings to a draft
/// var draft = AppDraft()
/// for binding in bindings {
///     try binding.apply(to: &draft, reader: configReader)
/// }
/// ```
public struct AnyBinding<Draft> {
    /// The configuration key this binding reads from.
    public let key: String

    /// Type-erased application closure.
    /// Decodes the value, validates it, and writes to the draft.
    private let _apply: (inout Draft, Configuration.ConfigReader) throws -> Void

    /// Creates a type-erased binding from a concrete `Binding`.
    ///
    /// - Parameter binding: The binding to wrap and type-erase
    public init<Value>(_ binding: Binding<Draft, Value>) {
        self.key = binding.key
        self._apply = { draft, reader in
            // Decode the value
            let decodedValue = try binding.decoder(reader, binding.key)

            // Use default if needed
            let valueToValidate = decodedValue ?? binding.defaultValue

            // If we have a value, validate and write it
            if let value = valueToValidate {
                // Run all value specs
                for spec in binding.valueSpecs {
                    let result = spec.validate(value)
                    if case .failure(let reason) = result {
                        // For now, throw a simple error (B4 will add proper types)
                        throw ConfigError.specFailed(key: binding.key, reason: reason)
                    }
                }

                // Write validated value to draft
                draft[keyPath: binding.keyPath] = value
            }
            // If no value and no default, leave draft field as nil (valid)
        }
    }

    /// Applies this binding to a draft by reading from the config reader.
    ///
    /// - Parameters:
    ///   - draft: The draft configuration object to mutate
    ///   - reader: The configuration reader to read values from
    /// - Throws: Decode errors or validation failures
    public func apply(to draft: inout Draft, reader: Configuration.ConfigReader) throws {
        try _apply(&draft, reader)
    }
}

/// Temporary error type for B2 (will be replaced by proper Diagnostics in B4)
enum ConfigError: Error {
    case specFailed(key: String, reason: String)
}
```

### Key Design Decisions

1. **Type Erasure via Closures:**
   - Store `_apply` closure that captures the binding logic
   - Closure signature doesn't mention `Value`, only `Draft`
   - This allows storing bindings with different `Value` types

2. **Simplified Error Handling:**
   - For B2, use simple `ConfigError` enum
   - B4 will replace this with proper `DiagnosticsReport`
   - Allows B2 to be testable without waiting for B4

3. **Preserving Key:**
   - Store `key` separately for easy access
   - Useful for error reporting and debugging
   - Doesn't require calling the closure to get the key

4. **Apply Method:**
   - Public interface for pipeline to use
   - Mutates draft in-place for performance
   - Throws on errors (will be caught by pipeline in C2)

---

## 5. Verification Commands

```bash
# Build should succeed
swift build

# Tests should pass
swift test --filter AnyBindingTests

# All tests should pass
swift test
```

**Expected Results:**
- Build succeeds
- At least 6 AnyBinding tests pass
- All existing tests still pass

---

## 6. Inputs

- B1: `Binding.swift` (dependency)
- PRD §5.2 (AnyBinding implementation intent)
- `Configuration` module from swift-configuration
- `SpecificationCore` module

---

## 7. Outputs

- `Sources/SpecificationConfig/AnyBinding.swift` (type erasure implementation)
- `Tests/SpecificationConfigTests/AnyBindingTests.swift` (comprehensive tests)
- Foundation for C1 (SpecProfile) and C2 (ConfigPipeline)

---

## 8. Dependencies

**Depends on:**
- B1 (Binding API) - REQUIRED

**Enables:**
- C1: SpecProfile (uses arrays of AnyBinding)
- C2: ConfigPipeline (applies AnyBindings)

---

## 9. Edge Cases and Considerations

| Scenario | Approach |
|---|---|
| Binding with no default and missing key | Leave draft field as nil (valid empty state) |
| Multiple specs, first passes, second fails | Short-circuit on first failure, throw immediately |
| Decoder throws | Propagate error up (pipeline will handle in C2) |
| Value fails spec validation | Throw error with key and reason |
| Draft field already has value | Overwrite with new value (last write wins) |

---

## 10. Definition of Done

- [x] `AnyBinding.swift` created with full type erasure implementation
- [x] Initializer accepts `Binding<Draft, Value>` and erases type
- [x] `apply` method correctly executes binding logic
- [x] Key property preserved through type erasure
- [x] Temporary `ConfigError` enum for error handling
- [x] `AnyBindingTests.swift` with 6+ passing tests (9 tests created)
- [x] Can store heterogeneous bindings in `[AnyBinding<Draft>]` array
- [x] `swift build` succeeds
- [x] `swift test` passes (all 10 tests pass)
- [x] Workplan marked B2 as `[x]`
- [x] This task PRD updated with completion status

---

## Notes

- Type erasure is a critical Swift pattern for working with generics
- The closure-based approach is performant and type-safe
- Simplified error handling now, full diagnostics in B4
- This unlocks the ability to have configuration profiles with multiple typed fields
- AnyBinding is purely a wrapper - no business logic, just type erasure
