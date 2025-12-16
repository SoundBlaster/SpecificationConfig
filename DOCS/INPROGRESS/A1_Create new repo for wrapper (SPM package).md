# Task PRD — A1 Create new repo for wrapper (SPM package)

## Source and context
- **Origin:** PRD §9, Phase A — Repository & package scaffolding.
- **Priority / Effort:** High / S.
- **Dependencies:** None.
- **Expected output:** Repo with MIT license and README stub.
- **Verification mode:** Manual review, with CI-aligned commands for local validation.

## Objective and scope
- Stand up the initial `SpecificationConfig` Swift Package Manager repository so downstream tasks (dependencies, bindings, pipeline) have a consistent scaffold.
- Deliver an MIT-licensed codebase with a minimal README and placeholder code/tests that build on supported platforms.

In scope:
- Single library product `SpecificationConfig` with library target and test target defined in `Package.swift`.
- Placeholder source at `Sources/SpecificationConfig/SpecificationConfig.swift` and matching test at `Tests/SpecificationConfigTests/SpecificationConfigTests.swift`.
- MIT `LICENSE` and README stub documenting purpose, requirements, and build/test commands.
- Ensure repository shape aligns with existing CI (`swift build -v`, `swift test -v`, optional `swiftformat --lint .`).

Out of scope:
- Implementing wrapper functionality or pipeline APIs.
- Creating demo app, tutorial content, or release tagging (covered by later tasks).

## Inputs, constraints, and assumptions
- **Inputs:** Empty/initial GitHub repository; Swift toolchain 5.9+; macOS 12+ / iOS 15+ targets per package manifest.
- **Constraints:** Keep module name `SpecificationConfig`; preserve compatibility with CI matrix (macOS + Linux).
- **Assumptions:** SwiftFormat available when running lint locally (per CI); no additional dependencies required for scaffold.

## Deliverables
- `Package.swift` defining the library product and test target.
- Placeholder implementation and test files under `Sources/SpecificationConfig/` and `Tests/SpecificationConfigTests/`.
- `LICENSE` containing the MIT license.
- `README.md` stub covering project summary, requirements, and build/test instructions.
- Repository structure compatible with `.github/workflows/ci.yml` (build, test, lint).

## Execution plan (checklist with acceptance criteria)
| Status | Subtask | Details | Acceptance criteria |
| --- | --- | --- | --- |
| [ ] | Initialize SPM package skeleton | Create `Package.swift` with product `SpecificationConfig`, targets `SpecificationConfig` and `SpecificationConfigTests`; add placeholder source/test files. | `swift build -v` succeeds; target names match PRD terminology; module compiles on macOS/Linux. |
| [ ] | Add licensing | Include MIT `LICENSE` file and ensure repository headers/reference align with MIT usage. | LICENSE present at repo root and references MIT; no conflicting licenses. |
| [ ] | Author README stub | Provide project overview, requirements, setup instructions, and build/test snippets matching CI commands. | README includes purpose statement, supported Swift/Xcode versions, and SPM build/test snippets. |
| [ ] | Validate repository shape against CI | Confirm paths and commands used in `.github/workflows/ci.yml` are satisfied by scaffold (build, test, optional SwiftFormat). | Running `swift build -v` and `swift test -v` succeeds; if SwiftFormat installed, `swiftformat --lint .` reports no format violations. |
| [ ] | Repository hygiene | Add basic `.gitignore` (if missing) for Swift/SwiftPM artifacts; ensure no stray files. | Git status clean after initial build/test; no generated artifacts committed. |

## Acceptance criteria (per subtask)
- **SPM skeleton:** Library target exports a compilable placeholder type; test target builds and executes a smoke test.
- **Licensing:** MIT license text present; README references MIT.
- **README stub:** Documents project intent and basic commands; links to LICENSE.
- **CI alignment:** Local execution of CI commands completes without additional setup beyond Swift toolchain.
- **Hygiene:** Repo ready for follow-on tasks without clean-up; structure matches `Sources/SpecificationConfig` and `Tests/SpecificationConfigTests`.

## Verification plan
- Commands to run locally (match CI):
  - `swift build -v`
  - `swift test -v`
  - `swiftformat --lint .` (optional; required if SwiftFormat available)
- Manual review: confirm LICENSE, README, and scaffold files exist with correct names/paths.

## Risks and mitigations
- **Cross-platform discrepancies:** CI runs on macOS and Linux—keep placeholder code free of Apple-only imports.  
  _Mitigation:_ Use pure Swift types only in scaffold.
- **Tooling drift:** SwiftFormat availability may vary locally.  
  _Mitigation:_ Treat lint as optional locally; CI will install when needed.

## Definition of done (aligned to PRD §12 for this task)
- Repository builds and tests cleanly with CI-aligned commands on supported platforms.
- MIT license and README stub are present and referenced.
- Scaffold provides a usable starting point for adding dependencies, bindings, and pipeline (enables progression to A2+).
- No unresolved setup work remains before implementing functional features.
