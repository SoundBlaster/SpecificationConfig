# I7 — Enhanced Documentation - Decoder Contract

## Summary

Added comprehensive decoder contract documentation to `Binding.decoder` property, clarifying:
- Return `nil` when key is missing (falls back to defaultValue)
- Return a value when decoding succeeds
- Throw when key exists but decoding fails (type mismatch, invalid format)
- Includes a code example showing URL validation pattern

## Files Changed

| File | Action |
|------|--------|
| `Sources/SpecificationConfig/Binding.swift` | Enhanced `decoder` property documentation |

**Archived:** 2026-01-28
