# Task PRD: B3 — Define Snapshot Model

**Task ID:** B3
**Phase:** B (Core types: Binding, AnyBinding, Snapshot, Diagnostics)
**Priority:** High
**Effort:** M (½–1d)
**Dependencies:** B1 (completed)
**Status:** Complete

---

## 1. Objective

Define the `Snapshot` model that captures the resolved configuration state, including values, provenance (source tracking), timing, and diagnostics. This provides visibility into where each configuration value came from and supports debugging/observability in the pipeline.

---

## 2. Scope

### In Scope
- Define `Snapshot` struct in `Snapshot.swift`
- Define `Provenance` enum for source tracking
- Define `ResolvedValue` struct for individual key-value pairs
- Support value stringification for display
- Support redaction for secret values
- Track timing information (when snapshot was created)
- Hold reference to diagnostics (will be fully implemented in B4)
- Add comprehensive unit tests
- Full DocC documentation

### Out of Scope
- Full DiagnosticsReport implementation (covered in B4)
- Actual pipeline that creates snapshots (covered in C2)
- Provenance capture from swift-configuration (covered in D2)
- UI display of snapshots (covered in E4/E5)

---

## 3. Task Breakdown

### Subtask 3.1: Define Provenance Enum
**Acceptance Criteria:**
- [ ] Create `Provenance` enum with cases:
  - `fileProvider(name: String)` - from a file provider
  - `environmentVariable` - from environment variables
  - `defaultValue` - from binding's default value
  - `unknown` - when source cannot be determined
- [ ] Make it `Sendable` and `Equatable`
- [ ] Add DocC documentation for each case

### Subtask 3.2: Define ResolvedValue Struct
**Acceptance Criteria:**
- [ ] Create `ResolvedValue` struct with properties:
  - `key: String` - configuration key
  - `stringifiedValue: String` - human-readable value (redacted if secret)
  - `provenance: Provenance` - where the value came from
  - `isSecret: Bool` - whether this value should be redacted
- [ ] Make it `Sendable` and `Equatable`
- [ ] Add computed property for display value (applies redaction)
- [ ] Add DocC documentation

### Subtask 3.3: Define Snapshot Struct
**Acceptance Criteria:**
- [ ] Create `Snapshot` struct with properties:
  - `resolvedValues: [ResolvedValue]` - all resolved configuration values
  - `timestamp: Date` - when snapshot was created
  - `diagnostics: [String]` - placeholder for diagnostics (B4 will replace)
- [ ] Make it `Sendable`
- [ ] Add convenience methods:
  - `value(forKey:)` to lookup a resolved value by key
  - `hasErrors` computed property (placeholder, will use real diagnostics in B4)
- [ ] Add DocC documentation

### Subtask 3.4: Implement Tests
**Acceptance Criteria:**
- [ ] Create `SnapshotTests.swift`
- [ ] Test provenance enum cases and equality
- [ ] Test ResolvedValue creation and redaction
- [ ] Test Snapshot creation and value lookup
- [ ] Test redaction behavior (secret values show "[REDACTED]")
- [ ] Test timestamp recording
- [ ] Minimum 8 tests covering all components
- [ ] All tests pass

### Subtask 3.5: Documentation
**Acceptance Criteria:**
- [ ] All public types have DocC documentation
- [ ] Include usage examples in doc comments
- [ ] Document redaction behavior
- [ ] Document provenance tracking purpose

---

## 4. Technical Design

### 4.1 Provenance Enum

```swift
/// Tracks the source of a resolved configuration value.
///
/// Provenance enables debugging by showing where each value originated:
/// file providers, environment variables, defaults, or unknown sources.
public enum Provenance: Sendable, Equatable {
    /// Value came from a file provider (JSON, YAML, etc.)
    case fileProvider(name: String)

    /// Value came from an environment variable
    case environmentVariable

    /// Value came from the binding's default value
    case defaultValue

    /// Source could not be determined
    case unknown
}
```

### 4.2 ResolvedValue Struct

```swift
/// A single resolved configuration value with its provenance.
public struct ResolvedValue: Sendable, Equatable {
    /// The configuration key
    public let key: String

    /// The stringified value (may be redacted)
    public let stringifiedValue: String

    /// Where this value came from
    public let provenance: Provenance

    /// Whether this value is a secret and should be redacted
    public let isSecret: Bool

    /// The display value with redaction applied
    public var displayValue: String {
        isSecret ? "[REDACTED]" : stringifiedValue
    }

    public init(
        key: String,
        stringifiedValue: String,
        provenance: Provenance,
        isSecret: Bool = false
    ) {
        self.key = key
        self.stringifiedValue = stringifiedValue
        self.provenance = provenance
        self.isSecret = isSecret
    }
}
```

### 4.3 Snapshot Struct

```swift
/// A snapshot of the resolved configuration state.
///
/// Captures all resolved values, their provenance, and any diagnostics
/// generated during the build process.
public struct Snapshot: Sendable {
    /// All resolved configuration values
    public let resolvedValues: [ResolvedValue]

    /// When this snapshot was created
    public let timestamp: Date

    /// Placeholder for diagnostics (will be typed in B4)
    public let diagnostics: [String]

    /// Whether this snapshot contains any errors
    public var hasErrors: Bool {
        // Placeholder: B4 will properly detect errors
        !diagnostics.isEmpty
    }

    public init(
        resolvedValues: [ResolvedValue] = [],
        timestamp: Date = Date(),
        diagnostics: [String] = []
    ) {
        self.resolvedValues = resolvedValues
        self.timestamp = timestamp
        self.diagnostics = diagnostics
    }

    /// Finds a resolved value by key
    public func value(forKey key: String) -> ResolvedValue? {
        resolvedValues.first { $0.key == key }
    }
}
```

---

## 5. Test Strategy

### 5.1 Unit Tests

#### Test 1: Provenance Equality
- Create two provenance values of same type
- Verify equality works correctly
- Test all four cases

#### Test 2: ResolvedValue Creation
- Create ResolvedValue with all properties
- Verify properties are set correctly
- Test both secret and non-secret values

#### Test 3: ResolvedValue Redaction
- Create secret ResolvedValue
- Verify `displayValue` returns "[REDACTED]"
- Create non-secret ResolvedValue
- Verify `displayValue` returns actual value

#### Test 4: Snapshot Creation
- Create empty Snapshot
- Verify default values
- Create Snapshot with values
- Verify values are stored

#### Test 5: Value Lookup
- Create Snapshot with multiple values
- Lookup existing key
- Verify correct value returned
- Lookup non-existent key
- Verify nil returned

#### Test 6: Timestamp Recording
- Create Snapshot
- Verify timestamp is recent (within 1 second)

#### Test 7: HasErrors Property
- Create Snapshot with empty diagnostics
- Verify hasErrors is false
- Create Snapshot with diagnostics
- Verify hasErrors is true

#### Test 8: Multiple Values with Different Provenance
- Create Snapshot with values from different sources
- Verify each provenance is tracked correctly

---

## 6. Success Criteria

### Functional Requirements
- [x] All PRD sections complete
- [ ] Provenance enum defined with 4 cases
- [ ] ResolvedValue struct captures key, value, provenance, secret flag
- [ ] Snapshot struct holds resolved values, timestamp, diagnostics
- [ ] Redaction works correctly for secret values
- [ ] Value lookup by key works

### Code Quality
- [ ] All types are `Sendable` (Swift 6 concurrency)
- [ ] Comprehensive DocC documentation
- [ ] Clean, readable code
- [ ] No force unwraps or unsafe operations

### Testing
- [ ] 8+ comprehensive unit tests
- [ ] All tests pass
- [ ] Tests cover all code paths
- [ ] Edge cases tested (empty snapshot, missing keys, etc.)

### Verification
- [ ] `swift build` succeeds
- [ ] `swift test` passes
- [ ] `swiftformat --lint .` passes
- [ ] No compiler warnings

---

## 7. Example Usage

```swift
// Create resolved values
let nameValue = ResolvedValue(
    key: "app.name",
    stringifiedValue: "MyApp",
    provenance: .fileProvider(name: "config.json"),
    isSecret: false
)

let apiKeyValue = ResolvedValue(
    key: "api.key",
    stringifiedValue: "secret123",
    provenance: .environmentVariable,
    isSecret: true
)

// Create snapshot
let snapshot = Snapshot(
    resolvedValues: [nameValue, apiKeyValue],
    timestamp: Date(),
    diagnostics: []
)

// Lookup values
if let name = snapshot.value(forKey: "app.name") {
    print(name.displayValue) // "MyApp"
    print(name.provenance)   // fileProvider("config.json")
}

if let apiKey = snapshot.value(forKey: "api.key") {
    print(apiKey.displayValue) // "[REDACTED]"
}

// Check for errors
if snapshot.hasErrors {
    print("Snapshot has diagnostics")
}
```

---

## 8. Dependencies

**Requires:**
- B1 (Binding API) - Not directly, but conceptually part of same system

**Enables:**
- B4: DiagnosticsReport (will type the diagnostics property)
- C2: ConfigPipeline (will create snapshots during builds)
- D2: Provenance capture (will populate provenance from swift-configuration)
- E4/E5: Demo UI (will display snapshots)

---

## 9. Edge Cases and Considerations

| Scenario | Approach |
|---|---|
| Empty snapshot (no values) | Valid - pipeline may fail early |
| Lookup non-existent key | Return nil gracefully |
| Secret value stringification | Always redact in displayValue |
| Timestamp precision | Use Date(), millisecond precision sufficient |
| Multiple values same key | Pipeline controls this, snapshot just stores |
| Diagnostics placeholder | Use String array until B4 defines proper types |

---

## 10. Definition of Done

- [x] `Snapshot.swift` created with all three types
- [x] `Provenance` enum with 4 cases + docs
- [x] `ResolvedValue` struct with redaction support + docs
- [x] `Snapshot` struct with lookup + docs
- [x] `SnapshotTests.swift` with 8+ passing tests (13 tests created)
- [x] All types are `Sendable`
- [x] `swift build` succeeds
- [x] `swift test` passes (all 29 tests pass)
- [x] `swiftformat --lint .` passes
- [x] Workplan marked B3 as `[x]`
- [x] This task PRD updated with completion status

---

## Notes

- Snapshot is a read-only view of configuration state
- The pipeline (C2) will be responsible for creating snapshots
- Provenance tracking will be enhanced in D2 when we integrate with swift-configuration
- The diagnostics property is a placeholder; B4 will replace String array with proper DiagnosticItem types
- This provides foundation for observability/debugging features
