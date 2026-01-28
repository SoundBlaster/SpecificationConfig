# I11 — YAML/TOML Support Examples

**Status:** Completed
**Archived:** 2026-01-28

## Summary

Added "Configuration Sources" section to README.md with examples for JSON, YAML, and provider stacking patterns.

## Changes

### Modified Files
- `README.md` — Added Configuration Sources section with JSON, YAML, and stacking examples

### Key Details
- JSON: Default trait, uses `FileProvider<JSONSnapshot>`
- YAML: Requires `YAML` trait in Package.swift dependency declaration
- TOML: Not available in swift-configuration (noted in README)
- Stacking: Showed environment → file → defaults precedence pattern

## Validation
- swift build clean
- swiftformat lint clean
