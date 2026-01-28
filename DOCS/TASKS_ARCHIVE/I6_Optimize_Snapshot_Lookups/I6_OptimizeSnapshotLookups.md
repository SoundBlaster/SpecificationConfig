# I6 — Optimize Snapshot Lookups

## Summary

Added pre-computed dictionary index (`resolvedValuesByKey`) to `Snapshot` for O(1) key lookups. The public `resolvedValues` array is preserved for backward compatibility. The `value(forKey:)` method now uses the dictionary, and `diff(from:)` reuses the pre-computed indexes instead of rebuilding dictionaries on each call.

## Files Changed

| File | Action |
|------|--------|
| `Sources/SpecificationConfig/Snapshot.swift` | Added `resolvedValuesByKey` private property; optimized `value(forKey:)` and `diff(from:)` |

**Archived:** 2026-01-28
