# I12 — Code Coverage Reporting

**Status:** Completed
**Archived:** 2026-01-28

## Summary

Added code coverage tracking and threshold enforcement to CI. The macOS test job now runs with `--enable-code-coverage` and a Python script parses the codecov JSON to report SpecificationConfig-only coverage (filtering out dependencies). Fails if coverage drops below 80%.

## Changes

### Modified Files
- `.github/workflows/ci.yml` — Added `--enable-code-coverage` flag and coverage reporting step

### Design Decisions
- **Filter to project sources only**: Dependencies (swift-configuration, SpecificationCore, swift-collections, etc.) are excluded from the coverage calculation to get an accurate picture of the project's own test coverage.
- **80% threshold**: Current coverage is 85.6%. Threshold set at 80% to allow some flexibility while ensuring high coverage is maintained.
- **Python-based parsing**: Uses `python3` (available on GitHub Actions macOS runners) to parse the codecov JSON file. No additional dependencies needed.

## Validation
- Local coverage: 85.6% (1393/1627 lines)
- CI YAML validated with Python yaml parser
- swift build clean
- swiftformat lint clean
