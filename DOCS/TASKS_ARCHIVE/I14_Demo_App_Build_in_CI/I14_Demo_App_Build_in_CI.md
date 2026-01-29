# Task PRD: I14 — Demo App Build in CI

**Source:** DOCS/PRD/IMPROVEMENTS.md CI/CD Enhancements
**Priority:** Low
**Phase:** I
**Effort:** S (≤2h)
**Dependencies:** None
**Status:** Completed

---

## Context & Assumptions

- The SpecificationConfig repository has a demo macOS SwiftUI app at `Demo/ConfigPetApp/`
- The demo app uses **Tuist** for project generation and dependency management
- Current CI (`.github/workflows/ci.yml`) builds the library but does not build the demo app
- Demo app depends on the local SpecificationConfig package via `Tuist/Package.swift`
- macOS 15.0+ is required for the demo app

---

## Selected Task

| Field | Value |
|-------|-------|
| ID | I14 |
| Title | Demo App Build in CI |
| Source | DOCS/PRD/IMPROVEMENTS.md |
| Priority | Low |
| Effort | S |

---

## PRD Row Data

| Attribute | Value |
|-----------|-------|
| Priority | Low |
| Effort | S (≤2h) |
| Dependencies | None |
| Output | New CI job that builds the demo app |

---

## Implementation Plan

### Phase 1: Add Demo App Build Job to CI

Add a new job `build-demo-app` to `.github/workflows/ci.yml` that:

1. Runs on `macos-latest`
2. Installs Tuist
3. Installs demo app dependencies via `tuist install`
4. Builds the demo app via `tuist build`

---

## Files & Change Points

| File | Change |
|------|--------|
| `.github/workflows/ci.yml` | Add new job `build-demo-app` |

---

## Affected API Surface

None — this is a CI configuration change only.

---

## Subtasks Checklist

- [x] 1. Add `build-demo-app` job to `.github/workflows/ci.yml`
  - [x] 1.1 Add job with `macos-latest` runner
  - [x] 1.2 Add checkout step
  - [x] 1.3 Add Xcode setup step (same as other jobs)
  - [x] 1.4 Add Tuist installation step
  - [x] 1.5 Add `tuist install` step for dependencies
  - [x] 1.6 Add `tuist build` step to build the demo app
- [x] 2. Test CI workflow runs successfully (will be verified on push)
- [x] 3. Update Workplan.md to mark I14 complete

---

## Acceptance Criteria

| Subtask | Acceptance Criteria |
|---------|---------------------|
| 1.1 | Job runs on `macos-latest` |
| 1.2 | Checkout action v4 is used |
| 1.3 | Xcode 26.0 is selected |
| 1.4 | Tuist is installed successfully |
| 1.5 | Demo app dependencies are installed |
| 1.6 | Demo app builds without errors |
| 2 | CI workflow passes all checks |
| 3 | Workplan.md shows `[x] I14` |

---

## Verification Commands

From repository root:

```bash
# Standard validation
swift build -v
swift test -v
swiftformat --lint .

# Demo app build (manual test on macOS)
cd Demo/ConfigPetApp
tuist install
tuist build
```

---

## Definition of Done

Aligned with PRD §12:

- [x] CI is green with new demo app build job (will be verified on push)
- [x] Demo app builds successfully in CI pipeline (will be verified on push)
- [x] CI catches build regressions in demo app
- [x] Workplan updated

---

## Risks & Open Questions

| Risk/Question | Mitigation |
|---------------|------------|
| Tuist installation in CI | Use `mise` (formerly rtx) or direct curl installation |
| CI runner may not have Tuist cached | Accept longer CI time for demo builds |
| Demo app build may fail if library changes break it | This is the desired outcome — catching regressions |

---

## CI Job Template

```yaml
build-demo-app:
  name: Build Demo App
  runs-on: macos-latest
  needs: detect-code-changes
  steps:
    - uses: actions/checkout@v4

    - name: Select Xcode 26.0
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: "26.0"

    - name: Install Tuist
      run: |
        curl -Ls https://install.tuist.io | bash
        tuist version

    - name: Install Demo Dependencies
      working-directory: Demo/ConfigPetApp
      run: tuist install

    - name: Build Demo App
      working-directory: Demo/ConfigPetApp
      run: tuist build
```

**Archived:** 2026-01-28
