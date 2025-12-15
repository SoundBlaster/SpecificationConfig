# XP-Inspired TDD Workflow (Outside-In)

## Mission Statement

You are an autonomous engineering agent practicing Extreme Programming with full test-driven development. Your task is
to grow the SpecificationConfig codebase from current state toward production-ready functionality by iterating from the
largest behavioral requirements toward the smallest implementation details. Maintain continuous delivery readiness at
all times.

## Guiding Principles

- **Outside-In Evolution:** Always start with the highest-level system behavior (acceptance tests, CLI usage, user workflows) and refine toward lower-level components only when driven by failing tests at the current level.

- **Always Green Main Branch:** Ensure the default branch can be released at any time. Every commit must keep the build,
tests, and deployment pipeline passing.

- **Test-First Mindset:** Do not write production code without a preceding failing test. Empty or pending tests are
acceptable only as placeholders that immediately fail and motivate implementation.

- **Incremental Learning:** Treat each iteration as an opportunity to refine architecture, improve clarity, and simplify
design while keeping feedback loops tight.

- **Automated Delivery:** Maintain automated build, test, and release workflows (via GitHub Actions) from the earliest
iterations.

## Phase Overview

### 1. Initialize the Delivery Skeleton

- Create or verify repository structure, Swift Package configuration, and dependency management (Package.swift).
- Add continuous integration workflow (GitHub Actions in `.github/workflows/`) that runs `swift build`, static checks, and `swift test`.
- Configure release tasks (e.g., GitHub releases) even if artifacts are placeholders.
- Commit minimal executable code that compiles and runs without performing business logic.

### 2. Author High-Level Acceptance Tests

- Define end-to-end or API-level tests expressing the primary behavior from a user perspective.
- Tests may exercise the public wrapper API and (later) the demo app flows described in `DOCS/PRD/SpecificationConfig_PRD.md`.
- Initially, tests may return canned or mock responses.
- Acceptance tests should currently fail, documenting the desired capabilities before implementation.

### 3. Drive Implementation Outside-In

- Choose one failing acceptance test and implement just enough high-level scaffolding to make it pass, stubbing deeper collaborators.
- When a stub prevents progress, write a new failing test at the next layer (e.g., binding → pipeline → diagnostics) to
  describe the required behavior.
- Repeat recursively: move downward only when higher-level expectations demand concrete behavior.
- Keep production code minimal; use duplication as a signal for refactoring once patterns emerge from multiple tests.

### 4. Refinement and Refactoring Cycle

- After each green build, refactor to remove duplication, clarify intent, and improve design.
- Maintain strict test coverage for all refactorings; no functionality changes without failing tests first.
- Continuously evolve test suites: upgrade placeholder assertions into meaningful expectations as features solidify.

### 5. Deployment and Release Readiness

- Ensure CI pipelines produce deployable artifacts on every run.
- Maintain versioning and changelog automation so that each merged change can be released without manual intervention.
- Periodically execute a dry-run deployment to validate scripts and infrastructure.

## Iteration Template

1. Pick the highest-priority failing acceptance test.
2. Write/adjust a lower-level test (parser test, resolver test, emitter test, etc.) that exposes the missing behavior.
3. Implement the simplest code to satisfy the new test.
4. Run the entire test suite and CI-equivalent checks locally: `swift build && swift test`.
5. Refactor while keeping tests green.
6. Commit with a descriptive message referencing the behavior enabled (e.g., "Add acceptance test for SELECT command execution").
7. Update release notes or documentation if external behavior changes.

## Swift and SpecificationConfig-Specific Guidelines

- **Modules:** Respect module boundaries defined in `Package.swift`. Today this repo ships a single library target
  (`SpecificationConfig`); as it grows, follow PRD §5.1 for the intended layout and keep types cohesive.
- **Test Structure:** Keep tests in `Tests/SpecificationConfigTests/` unless you add new SPM targets that justify new
  test targets.
- **API First:** Start with the public wrapper API behavior (bindings, pipeline execution, deterministic diagnostics).
  Treat the demo app as an integration surface once it exists.
- **Build Validation:** After each change, run `swift build` to catch compilation errors early.
  Run `swift test` to validate behavior against the test suite.

## Documentation Expectations

- Maintain a living architecture README (or document in DOCS/) that mirrors the current system boundaries and module responsibilities.
- For each completed task (iteration), record in DOCS/INPROGRESS/:
  - The acceptance test scenario addressed.
  - Newly introduced components or collaborators.
  - Refactorings performed and their rationale.
- Keep developer onboarding instructions current with the evolving build and deployment process.
  (See: `DOCS/RULES/01_Swift_Install.md` for setup guidance.)

## Communication and Collaboration Norms

- Pairing and mobbing are encouraged; when operating solo, document rationale for significant architectural decisions in commit messages.
- Use feature flags or conditional compilation when partially implementing features to keep the main branch deployable.
- Prefer small, frequent commits aligned with single acceptance scenarios or test-driven refinements.

## Definition of Done

- All relevant tests (acceptance, integration, unit) pass locally and in CI (`swift build`, `swift test`).
- Build, package, and release automation completes successfully with current changes.
- Documentation and release notes reflect the implemented behavior.
- No outstanding TODOs or FIXMEs without linked follow-up issues.

## Execution Workflow Integration

This TDD workflow integrates with the EXECUTE command (see DOCS/COMMANDS/EXECUTE.md):

1. **PLAN** command produces a detailed PRD with acceptance criteria and implementation steps.
2. **EXECUTE** command runs pre-flight checks, shows the plan, and supervises post-flight validation.
3. **Developer/agent implements** using this TDD workflow: outside-in, test-first, iterative.
4. **Post-flight validation** runs `swift build` and `swift test` to ensure all checks pass before commit.

Adhere to this workflow rigorously to embody outside-in TDD within an Extreme Programming context, ensuring that
SpecificationConfig evolves with high quality and continuous delivery readiness.
