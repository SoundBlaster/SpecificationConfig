# Task PRD: D3 — Manual reload API

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** D3
**Priority:** Medium
**Effort:** Small (≤2h)
**Dependencies:** C2 (ConfigPipeline)

---

## 1. Objective

Add a manual reload API to rebuild configuration with the same profile and reader without requiring the application to manually re-invoke `ConfigPipeline.build()` with stored parameters.

**Current State:**
Applications must manually store the profile and reader, then call `ConfigPipeline.build()` again for reload:
```swift
// Application must manage these
let profile = myProfile
let reader = myReader

// Initial load
var result = ConfigPipeline.build(profile: profile, reader: reader)

// Reload requires re-passing everything
result = ConfigPipeline.build(profile: profile, reader: reader)
```

**Target State:**
Provide a stateful API that encapsulates profile + reader and offers a simple reload method:
```swift
// Create loader once
let loader = ConfigLoader(profile: myProfile, reader: myReader)

// Initial load
var result = loader.build()

// Reload is simple
result = loader.reload()
```

**Source:** PRD §9 Phase D, Task D3

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. New `ConfigLoader<Draft, Final>` type that encapsulates profile + reader
2. `build()` method that delegates to `ConfigPipeline.build()`
3. `reload()` method as an alias for `build()` (semantically clearer)
4. Thread-safe access if ConfigReader is thread-safe
5. Comprehensive tests verifying reload behavior
6. Documentation with usage examples

### 2.2 What this task does NOT deliver

- Automatic file watching or hot reload (that's F6)
- Caching of previous results (not needed for MVP)
- Callback/notification system for reload events
- Diff computation between old and new config
- State management for UI updates (application responsibility)

### 2.3 Success Criteria

- [x] `ConfigLoader` type exists with generic Draft + Final
- [x] Can create loader with profile + reader
- [x] `build()` method returns `BuildResult<Final>`
- [x] `reload()` method exists and works identically to `build()`
- [x] Tests verify multiple reload calls work correctly
- [x] Tests verify each reload gets fresh values from reader
- [x] Documentation includes usage examples
- [x] All existing tests continue to pass
- [x] SwiftFormat compliance maintained

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: ConfigLoader initialization**
- Accept `SpecProfile<Draft, Final>` and `ConfigReader` on initialization
- Store references for later reload calls
- Support optional `ErrorHandlingMode` parameter (default: `.collectAll`)

**Acceptance Criteria:**
- Can create loader with profile + reader
- Stored profile and reader are used for all build calls
- Error handling mode can be specified at construction
- Error handling mode applies to all build/reload calls

**FR-2: Build method**
- Provide `build()` method that delegates to `ConfigPipeline.build()`
- Return `BuildResult<Final>` with diagnostics and snapshot
- Use stored profile, reader, and error handling mode

**Acceptance Criteria:**
- `loader.build()` produces identical results to `ConfigPipeline.build(profile, reader)`
- Diagnostics and snapshot are complete
- Error handling mode is respected

**FR-3: Reload method**
- Provide `reload()` method as semantic alias for `build()`
- Internally calls same logic as `build()`
- Returns fresh `BuildResult<Final>` each time

**Acceptance Criteria:**
- `reload()` and `build()` are functionally identical
- Multiple reload calls produce fresh results
- Each reload re-reads from ConfigReader
- No caching or stale data between reloads

**FR-4: Stateless rebuild behavior**
- Each `build()`/`reload()` call is independent
- No caching of previous Draft or Final values
- Each call creates fresh Draft via `makeDraft()`
- Fresh diagnostics and snapshot for each call

**Acceptance Criteria:**
- Changing config source between reloads reflects in results
- No state pollution between reload calls
- Each reload starts from clean Draft

### 3.2 Non-Functional Requirements

**NFR-1: Performance**
- Minimal overhead vs direct `ConfigPipeline.build()` call
- No unnecessary copying of profile or reader
- Store references, not deep copies

**NFR-2: Thread safety**
- If ConfigReader is thread-safe, loader should be usable from multiple threads
- Document thread-safety guarantees (or lack thereof)
- No internal mutable state beyond stored immutable references

**NFR-3: API clarity**
- Method names clearly convey intent (`reload()` vs `build()`)
- Documentation explains when to use each method
- Examples show typical usage patterns

**NFR-4: Testability**
- Can test reload behavior with mock ConfigReader
- Can verify reader is called on each reload
- Can test error handling mode persistence

---

## 4. Technical Design

### 4.1 Implementation Approach

Add a new `ConfigLoader` type that wraps `SpecProfile` and `ConfigReader`, providing a convenient reload API without changing `ConfigPipeline`.

### 4.2 ConfigLoader Type Definition

```swift
/// A stateful configuration loader that encapsulates a profile and reader
/// for convenient reloading without re-specifying parameters.
///
/// Use `ConfigLoader` when you need to reload configuration multiple times
/// (e.g., in response to a "Reload" button or file change event) without
/// manually passing the profile and reader each time.
///
/// ## Example
///
/// ```swift
/// let loader = ConfigLoader(
///     profile: myProfile,
///     reader: configReader,
///     errorHandlingMode: .collectAll
/// )
///
/// // Initial load
/// let result = loader.build()
///
/// // Later, reload after config file changes
/// let newResult = loader.reload()
/// ```
public struct ConfigLoader<Draft, Final> {
    private let profile: SpecProfile<Draft, Final>
    private let reader: Configuration.ConfigReader
    private let errorHandlingMode: ErrorHandlingMode

    /// Creates a configuration loader with the specified profile and reader.
    ///
    /// - Parameters:
    ///   - profile: The specification profile defining bindings and finalization.
    ///   - reader: The configuration reader supplying values.
    ///   - errorHandlingMode: Strategy for handling errors (default: `.collectAll`).
    public init(
        profile: SpecProfile<Draft, Final>,
        reader: Configuration.ConfigReader,
        errorHandlingMode: ErrorHandlingMode = .collectAll
    ) {
        self.profile = profile
        self.reader = reader
        self.errorHandlingMode = errorHandlingMode
    }

    /// Builds configuration using the stored profile and reader.
    ///
    /// Each call creates a fresh draft and re-reads from the configuration reader.
    /// No caching or state is maintained between calls.
    ///
    /// - Returns: Build result containing either success (final config + snapshot)
    ///            or failure (diagnostics + partial snapshot).
    public func build() -> BuildResult<Final> {
        ConfigPipeline.build(
            profile: profile,
            reader: reader,
            errorHandlingMode: errorHandlingMode
        )
    }

    /// Reloads configuration using the stored profile and reader.
    ///
    /// This is semantically equivalent to `build()` but more clearly conveys
    /// the intent of refreshing configuration from potentially changed sources.
    ///
    /// Each reload creates a fresh draft and re-reads all configuration values,
    /// producing updated diagnostics and snapshot.
    ///
    /// - Returns: Build result containing either success (final config + snapshot)
    ///            or failure (diagnostics + partial snapshot).
    public func reload() -> BuildResult<Final> {
        build()
    }
}
```

### 4.3 File Organization

Add new file: `Sources/SpecificationConfig/ConfigLoader.swift`

### 4.4 Key Design Decisions

**1. Struct vs Class**
- Use `struct` for value semantics
- Profile and reader are reference types, so copying ConfigLoader is cheap
- No internal mutable state, so no need for class semantics

**2. Reload as Alias**
- `reload()` simply calls `build()` internally
- Provides semantic clarity for reload use case
- Both methods documented and public

**3. No Caching**
- Each build/reload is completely fresh
- Simplifies implementation and reasoning
- Performance is not a concern for manual reload (user-triggered)

**4. Error Handling Mode Storage**
- Store at construction time, apply to all builds
- Consistent behavior across reload calls
- Can create new loader if different mode needed

**5. Public API Placement**
- Keep ConfigPipeline as primary low-level API
- ConfigLoader is convenience wrapper
- Applications can choose which to use

---

## 5. Implementation Plan

### Phase 1: Create ConfigLoader Type
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [x] Create `Sources/SpecificationConfig/ConfigLoader.swift`
2. [x] Define `ConfigLoader<Draft, Final>` struct
3. [x] Add stored properties: profile, reader, errorHandlingMode
4. [x] Implement `init(profile:reader:errorHandlingMode:)`
5. [x] Add documentation comments with examples

**Verification:**
- Code compiles
- No SwiftFormat violations

### Phase 2: Implement Build Methods
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] Implement `build()` method delegating to `ConfigPipeline.build()`
2. [x] Implement `reload()` method calling `build()`
3. [x] Add documentation explaining behavior and differences
4. [x] Add usage examples in comments

**Verification:**
- Methods compile and return correct types
- Documentation is clear

### Phase 3: Test Coverage
**Estimated time:** 40-50 minutes

**Subtasks:**
1. [x] Create `Tests/SpecificationConfigTests/ConfigLoaderTests.swift`
2. [x] Test: basic build() works and matches ConfigPipeline.build()
3. [x] Test: reload() works and produces fresh results
4. [x] Test: multiple reloads work correctly
5. [x] Test: reload reflects changed config values
6. [x] Test: error handling mode is preserved across reloads
7. [x] Test: build() and reload() are functionally equivalent

**Verification:**
- All new tests pass
- All existing tests continue to pass

### Phase 4: Documentation and Examples
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Add usage examples to ConfigLoader documentation
2. [x] Document thread-safety characteristics
3. [x] Document relationship to ConfigPipeline
4. [x] Update any relevant guides if needed

**Verification:**
- Documentation builds without warnings
- Examples are clear and executable

### Phase 5: Final Verification
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Run `swift build -v`
2. [x] Run `swift test -v`
3. [x] Run `swiftformat --lint .`
4. [x] Manual review of API ergonomics
5. [x] Check that ConfigLoader is exported in module

**Verification:**
- All verification commands succeed
- API is clean and intuitive

---

## 6. Test Plan

### 6.1 New Test Cases

| Test Name | Purpose | Expected Outcome |
|-----------|---------|------------------|
| `testConfigLoaderBuild` | Verify basic build works | Returns success with correct config |
| `testConfigLoaderReload` | Verify reload works | Returns fresh result |
| `testConfigLoaderMultipleReloads` | Verify repeated reloads | Each reload produces valid result |
| `testConfigLoaderReflectsChanges` | Verify reload sees config changes | New values appear after reload |
| `testConfigLoaderErrorHandlingMode` | Verify mode preserved | collectAll vs failFast behavior consistent |
| `testConfigLoaderBuildAndReloadEquivalent` | Verify build() == reload() | Results are identical |
| `testConfigLoaderWithFailure` | Verify error handling | Failures reported correctly |
| `testConfigLoaderSnapshot` | Verify snapshot generation | Each reload produces valid snapshot |

### 6.2 Test Implementation Strategy

Use `InMemoryProvider` (from existing tests) to simulate config source:
```swift
func testConfigLoaderReflectsChanges() {
    var values = ["app.name": "InitialName"]
    let provider = InMemoryProvider(values: values)
    let reader = ConfigReader(provider: provider)

    let loader = ConfigLoader(profile: testProfile, reader: reader)

    // Initial build
    let result1 = loader.build()
    // Assert result1 has "InitialName"

    // Simulate config change
    values["app.name"] = "UpdatedName"
    // Note: Need to handle provider mutability

    // Reload
    let result2 = loader.reload()
    // Assert result2 has "UpdatedName"
}
```

### 6.3 Edge Cases

| Edge Case | Expected Behavior | Test Coverage |
|-----------|-------------------|---------------|
| Reload after initial failure | Works correctly, retries full pipeline | New test |
| Reload with no config changes | Returns identical results | Covered by multiple reloads test |
| Reload with partial config changes | Only changed values differ | New test |
| Concurrent reloads (if reader is thread-safe) | Both succeed independently | Optional / document only |

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Build the package
swift build -v

# 2. Run all tests
swift test -v

# 3. Run only new tests
swift test -v --filter ConfigLoaderTests

# 4. Run existing tests to ensure no regression
swift test -v --filter PipelineTests

# 5. Verify code formatting
swiftformat --lint .
```

**Success Criteria:**
- All commands exit with status 0
- ConfigLoaderTests demonstrate reload functionality
- Existing tests continue to pass (backward compatibility)
- No SwiftFormat violations

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| C2 (ConfigPipeline) | Required | ✅ Complete | Core build logic |
| C1 (SpecProfile) | Required | ✅ Complete | Profile definition |
| B2 (AnyBinding) | Required | ✅ Complete | Used by profile |
| Swift Configuration | Required | ✅ Available | ConfigReader type |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| ConfigReader mutability unclear | Medium | Low | Document expected behavior; use in-memory provider for tests |
| Thread-safety requirements unclear | Low | Medium | Document as caller's responsibility; ConfigLoader is stateless |
| Reload doesn't refresh if reader caches | Medium | Low | Document expectation; provide clear examples |
| API naming confusion (build vs reload) | Low | Low | Clear documentation; both methods public |

---

## 9. Definition of Done

This task is complete when:

- [x] ⏳ `ConfigLoader<Draft, Final>` type exists
- [x] ⏳ `init(profile:reader:errorHandlingMode:)` implemented
- [x] ⏳ `build()` method delegates to ConfigPipeline
- [x] ⏳ `reload()` method works as alias to build()
- [x] ⏳ Error handling mode preserved across reloads
- [x] ⏳ Tests verify basic build functionality
- [x] ⏳ Tests verify reload produces fresh results
- [x] ⏳ Tests verify multiple reloads work correctly
- [x] ⏳ Tests verify config changes reflected in reload
- [x] ⏳ Documentation includes usage examples
- [x] ⏳ All existing tests pass (backward compatibility)
- [x] ⏳ Verification commands succeed
- [x] ⏳ SwiftFormat compliance maintained
- [x] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Integration with Demo App

This API is designed for use in the demo app (E4 - UI with Reload button):

```swift
// In demo app
class ConfigViewModel: ObservableObject {
    private let loader: ConfigLoader<AppConfigDraft, AppConfig>

    @Published var config: AppConfig?
    @Published var errors: [DiagnosticItem] = []

    init(loader: ConfigLoader<AppConfigDraft, AppConfig>) {
        self.loader = loader
        reload()
    }

    func reload() {
        let result = loader.reload()
        switch result {
        case let .success(config, _):
            self.config = config
            self.errors = []
        case let .failure(diagnostics, _):
            self.config = nil
            self.errors = diagnostics.diagnostics
        }
    }
}
```

### 10.2 Alternative Design Considered

**Stateful caching approach:**
- Store last `BuildResult` in loader
- Provide `diff()` method to compare old vs new
- **Rejected:** Adds complexity; out of scope for D3; can be added later if needed

**Callback-based approach:**
- Accept callback closure to notify on reload
- **Rejected:** Not needed for manual reload; better suited for F6 (watching)

**Builder pattern approach:**
- `ConfigLoader.builder().withProfile().withReader().build()`
- **Rejected:** Over-engineered for simple use case

### 10.3 Future Enhancements (Out of Scope)

These are explicitly NOT part of D3 but could be added later:

1. **Automatic watching (F6):** File system monitoring triggering auto-reload
2. **Result caching:** Store last result for diffing
3. **Reload callbacks:** Notify observers of reload events
4. **Reload history:** Track reload attempts for debugging
5. **Conditional reload:** Only reload if config changed

---

## Appendix A: Usage Examples

### Example 1: Basic Usage

```swift
import SpecificationConfig
import Configuration

// Define profile (one-time setup)
let profile = SpecProfile(
    bindings: [nameBinding, portBinding],
    finalize: { try AppConfig(draft: $0) },
    makeDraft: { AppConfigDraft() }
)

// Create reader
let provider = FileProvider(path: "config.json")
let reader = ConfigReader(provider: provider)

// Create loader
let loader = ConfigLoader(profile: profile, reader: reader)

// Initial load
let result = loader.build()

// Later, after config file changes
let reloadedResult = loader.reload()
```

### Example 2: UI Integration

```swift
// SwiftUI view model
@MainActor
class ConfigManager: ObservableObject {
    @Published var appConfig: AppConfig?
    @Published var errorMessage: String?

    private let loader: ConfigLoader<AppConfigDraft, AppConfig>

    init(loader: ConfigLoader<AppConfigDraft, AppConfig>) {
        self.loader = loader
    }

    func loadConfig() {
        handleResult(loader.build())
    }

    func reloadConfig() {
        handleResult(loader.reload())
    }

    private func handleResult(_ result: BuildResult<AppConfig>) {
        switch result {
        case let .success(config, _):
            appConfig = config
            errorMessage = nil
        case let .failure(diagnostics, _):
            appConfig = nil
            errorMessage = diagnostics.summary
        }
    }
}
```

### Example 3: Testing Reload Behavior

```swift
func testReloadSeesUpdates() {
    // Setup mutable provider
    let provider = MutableInMemoryProvider([
        "app.name": "Original"
    ])
    let reader = ConfigReader(provider: provider)
    let loader = ConfigLoader(profile: testProfile, reader: reader)

    // Initial load
    let result1 = loader.build()
    XCTAssertEqual(result1.config?.name, "Original")

    // Update config source
    provider.setValue("Updated", forKey: "app.name")

    // Reload sees new value
    let result2 = loader.reload()
    XCTAssertEqual(result2.config?.name, "Updated")
}
```

---

## Appendix B: Related Files

| File | Purpose | Changes |
|------|---------|---------|
| `Sources/SpecificationConfig/ConfigLoader.swift` | New file | ConfigLoader implementation |
| `Sources/SpecificationConfig/Pipeline.swift` | Existing | No changes (ConfigLoader delegates to it) |
| `Sources/SpecificationConfig/SpecProfile.swift` | Existing | No changes |
| `Tests/SpecificationConfigTests/ConfigLoaderTests.swift` | New file | Test coverage for ConfigLoader |

---

**End of PRD**
**Archived:** 2025-12-18
