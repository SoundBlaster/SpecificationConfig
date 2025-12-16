# Workplan

Linear to-do list derived from `DOCS/PRD/SpecificationConfig_PRD.md`.

- [x] A1 (High): Create new repo for wrapper (SPM package)
- [ ] A2 (High): Add dependencies: swift-configuration + SpecificationCore
- [ ] A3 (Medium): Add Docs/Tutorial structure with placeholder files
- [ ] B1 (High): Define `Binding<Draft, Value>` public API
- [ ] B2 (High): Implement `AnyBinding<Draft>` type erasure
- [ ] B3 (High): Define `Snapshot` model (values + provenance)
- [ ] B4 (High): Define `DiagnosticsReport` & error items
- [ ] B5 (Medium): Add `Redaction` support (secret flag)
- [ ] C1 (High): Implement `SpecProfile<Draft, Final>`
- [ ] C2 (High): Implement `ConfigPipeline` (build result: success/failure)
- [ ] C3 (High): Deterministic ordering of diagnostics
- [ ] C4 (Medium): Add collect-all vs fail-fast option
- [ ] D1 (High): Add minimal helpers for reading primitives
- [ ] D2 (High): Provenance capture strategy
- [ ] D3 (Medium): Manual reload API (rebuild with same profile/reader)
- [ ] E1 (High): Create macOS SwiftUI app target (Demo/ConfigPetApp)
- [ ] E2 (High): Add config file loader (config.json in app working dir)
- [ ] E3 (High): Implement `AppConfig` + `Draft` + `SpecProfile` for v0
- [ ] E4 (High): UI split view + Reload button
- [ ] E5 (High): UI error list panel when build fails
- [ ] F1 (High): Write `Docs/Tutorial/01_MVP.md` matching v0
- [ ] F2 (High): Tag repo `tutorial-v0`
- [ ] F3 (Medium): Add ENV override step + doc (`02_EnvOverrides.md`)
- [ ] F4 (Medium): Add value specs step + doc (`03_ValueSpecs.md`)
- [ ] F5 (Medium): Add decision fallback step + doc (`04_Decisions.md`)
- [ ] F6 (Low): Optional watching step + doc (`05_Watching.md`)
- [ ] G1 (High): GitHub Actions: build + test on macOS
- [ ] G2 (High): README “Why this wrapper” + quickstart
- [ ] G3 (Medium): 0.1.0 release checklist + changelog
