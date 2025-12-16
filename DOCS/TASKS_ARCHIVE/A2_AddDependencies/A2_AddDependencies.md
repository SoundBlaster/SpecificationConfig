# Task PRD: A2 — Add Dependencies

**Task ID:** A2
**Phase:** A (Repository & package scaffolding)
**Priority:** High
**Effort:** S (≤2h)
**Dependencies:** A1 (completed)
**Status:** Completed

---

## 1. Objective

Add external package dependencies to `Package.swift` for the SpecificationConfig wrapper library:

1. **swift-configuration** from Apple (provides ConfigReader and configuration providers)
2. **SpecificationCore** from SoundBlaster (provides Specification protocol and composable validation)

Ensure the package builds successfully with these dependencies and that basic imports work.

---

## 2. Scope

### In Scope
- Modify `Package.swift` to add both dependencies
- Ensure correct repository URLs and version constraints
- Verify the package builds without errors
- Verify imports work in the main target

### Out of Scope
- Implementing any logic using these dependencies (that comes in Phase B and later)
- Adding demo app dependencies
- Documentation or usage examples

---

## 3. Task Breakdown

### Subtask 3.1: Research Dependency URLs and Versions
**Acceptance Criteria:**
- [ ] Identify the correct GitHub URL for `apple/swift-configuration`
- [ ] Identify the correct GitHub URL for `SoundBlaster/SpecificationCore`
- [ ] Determine appropriate version constraints (prefer latest stable or main branch)

### Subtask 3.2: Update Package.swift Dependencies Section
**Acceptance Criteria:**
- [ ] Add `.package(url:branch:)` or `.package(url:from:)` entries for both dependencies
- [ ] Add dependency references to the `SpecificationConfig` target
- [ ] Ensure correct module names are used

**Expected Changes:**
```swift
// In Package.swift:
dependencies: [
    .package(url: "https://github.com/apple/swift-configuration.git", ...),
    .package(url: "https://github.com/SoundBlaster/SpecificationCore.git", ...),
],
targets: [
    .target(
        name: "SpecificationConfig",
        dependencies: [
            .product(name: "Configuration", package: "swift-configuration"),
            .product(name: "SpecificationCore", package: "SpecificationCore"),
        ]
    ),
    // ...
]
```

### Subtask 3.3: Verify Build with Dependencies
**Acceptance Criteria:**
- [ ] Run `swift build -v` and confirm successful resolution and build
- [ ] No compilation errors or dependency resolution failures

### Subtask 3.4: Add Minimal Import Verification
**Acceptance Criteria:**
- [ ] Create or update a minimal Swift file in `Sources/SpecificationConfig/` that imports both modules
- [ ] Verify imports compile without errors

**Example:**
```swift
// Sources/SpecificationConfig/SpecificationConfig.swift
import Configuration
import SpecificationCore

// Placeholder for future implementation
```

---

## 4. Verification Commands

Run these commands in sequence to verify completion:

```bash
# 1. Resolve dependencies
swift package resolve

# 2. Build the package
swift build -v

# 3. Run tests (should pass even if empty)
swift test -v
```

**Expected Results:**
- All commands complete successfully
- No errors related to missing dependencies
- Build artifacts are created

---

## 5. Inputs

- Current `Package.swift` (exists from A1)
- Dependency repository information:
  - Apple swift-configuration repository
  - SoundBlaster SpecificationCore repository

---

## 6. Outputs

- Updated `Package.swift` with two dependencies
- Successful build confirmation
- Ready for Phase B implementation tasks

---

## 7. Edge Cases and Failure Scenarios

| Scenario | Mitigation |
|---|---|
| Dependency repository URL incorrect | Verify URLs from official sources; check repository existence |
| Version/branch incompatibility | Try `.branch("main")` initially; adjust based on availability |
| Product name mismatch | Check each repository's Package.swift for correct product names |
| Build failure due to platform compatibility | Verify minimum platform versions in dependencies match our Package.swift |

---

## 8. Definition of Done

- [x] `Package.swift` contains both dependencies with correct URLs
- [x] `swift build -v` completes successfully
- [x] `swift test -v` runs (passes or shows only empty test results)
- [x] Basic imports (`import Configuration` and `import SpecificationCore`) compile
- [x] Workplan marked A2 as `[x]`
- [x] This task PRD updated with completion status

## 9. Completion Notes

**Completed:** 2025-12-16

**Dependencies Added:**
- `apple/swift-configuration` v1.0.0
- `SoundBlaster/SpecificationCore` v1.0.0

**Verification Results:**
- Dependencies resolved successfully
- Build completed without errors
- All tests passed (1 test)
- Imports verified in `Sources/SpecificationConfig/SpecificationConfig.swift`

---

## Notes

- Swift Configuration may still be in development; if main branch is unstable, document the specific commit or tag used
- SpecificationCore repository location confirmed as SoundBlaster/SpecificationCore per PRD
- This task enables all Phase B tasks that depend on these APIs

---

**Archived:** 2025-12-16
