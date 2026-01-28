# I11 — YAML/TOML Support Examples

**Status:** Planned
**Priority:** Low
**Phase:** I
**Dependencies:** None

## Problem

Only in-memory configuration examples are shown in the README. Users don't know how to use file-based providers (JSON, YAML) with SpecificationConfig.

## Solution

Add a "Configuration Sources" section to README.md showing:
1. JSON file usage via `FileProvider<JSONSnapshot>`
2. YAML file usage via `FileProvider<YAMLSnapshot>` (requires YAML trait)
3. Stacking multiple providers (env → file → defaults)
4. Note that TOML is not currently supported by swift-configuration

## Implementation

### Files to Modify
- `README.md` — Add "Configuration Sources" section after Quickstart

### Notes
- `FileProvider<JSONSnapshot>` requires the `JSON` trait (default)
- `FileProvider<YAMLSnapshot>` requires the `YAML` trait (must be explicitly enabled)
- swift-configuration uses SPM traits (6.2+) for conditional compilation
- No TOML support exists in swift-configuration

## Validation
- `swift build` clean
- `swift test` all pass
- `swiftformat --lint .` clean
